package com.juandpt.flutter_rasp

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.juandpt.flutter_rasp_core.DetectorRegistry
import com.juandpt.flutter_rasp_core.ScreenCaptureManager
import com.juandpt.flutter_rasp_core.reporter.Reporter
import com.juandpt.flutter_rasp_core.reporter.ReporterConfig
import com.juandpt.flutter_rasp_core.reporter.collectors.AppMetadataCollector
import com.juandpt.flutter_rasp_core.reporter.collectors.DeviceIdProvider
import com.juandpt.flutter_rasp_core.reporter.collectors.DeviceMetadataCollector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class FlutterRaspPlugin : FlutterPlugin, FlutterRaspHostApi, ActivityAware {

    companion object {
        private const val TAG = "FlutterRASP"
    }

    private var flutterApi: FlutterRaspFlutterApi? = null
    private var applicationContext: android.content.Context? = null
    @Volatile private var activity: Activity? = null
    private val screenCaptureManager = ScreenCaptureManager()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var scheduledExecutor: ScheduledExecutorService? = null
    private var monitoringFuture: ScheduledFuture<*>? = null
    @Volatile private var enabledThreats: List<String>? = null
    @Volatile private var exitThreats: List<String> = emptyList()
    @Volatile private var monitoringActive = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        FlutterRaspHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = FlutterRaspFlutterApi(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FlutterRaspHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        stopMonitoringInternal()
        enabledThreats = null
        exitThreats = emptyList()
        applicationContext = null
    }


    override fun startMonitoring(config: RaspConfigMessage, callback: (Result<Unit>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(noContextFailure())
            return
        }

        enabledThreats = config.enabledThreats
        exitThreats = config.exitThreats
        val interval = config.monitoringIntervalMs.toLong()
        config.androidConfig?.let { applyAndroidConfig(it) }
        Reporter.get()?.setActivePolicy(config.exitThreats)

        startMonitoringInternal(context, interval)
        callback(Result.success(Unit))
    }

    override fun stopMonitoring(callback: (Result<Unit>) -> Unit) {
        stopMonitoringInternal()
        enabledThreats = null
        exitThreats = emptyList()
        callback(Result.success(Unit))
    }

    override fun checkThreat(threatName: String, callback: (Result<Boolean>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(noContextFailure())
            return
        }
        Thread {
            val detected = DetectorRegistry.detect(threatName, context)
            mainHandler.post { callback(Result.success(detected)) }
        }.start()
    }

    override fun scanAll(enabledThreats: List<String>, callback: (Result<ScanResultMessage>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(noContextFailure())
            return
        }
        Thread {
            val detected = DetectorRegistry.detectAll(context, enabledThreats)
            val entries = detected.map { (name, value) ->
                ThreatResultEntry(threatName = name, detected = value)
            }
            val message = ScanResultMessage(results = entries)
            mainHandler.post { callback(Result.success(message)) }
        }.start()
    }

    override fun blockScreenCapture(enabled: Boolean, callback: (Result<Unit>) -> Unit) {
        val currentActivity = activity
        if (currentActivity == null) {
            callback(
                Result.failure(
                    FlutterError(
                        "SCREEN_CAPTURE_NO_ACTIVITY",
                        "No active Activity available to block screen capture",
                        null,
                    ),
                ),
            )
            return
        }
        screenCaptureManager.block(currentActivity, enabled)
        callback(Result.success(Unit))
    }

    override fun isScreenCaptureBlocked(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(screenCaptureManager.isBlocked()))
    }


    override fun initReporter(
        config: ReporterConfigMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        val context = applicationContext
        if (context == null) {
            callback(noContextFailure())
            return
        }
        try {
            Reporter.init(context, config.toCoreConfig())
            callback(Result.success(Unit))
        } catch (e: Throwable) {
            Log.w(TAG, "initReporter failed: ${e.message}")
            callback(Result.failure(e))
        }
    }

    override fun disposeReporter(callback: (Result<Unit>) -> Unit) {
        Reporter.dispose()
        callback(Result.success(Unit))
    }

    override fun addBreadcrumb(
        breadcrumb: BreadcrumbMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        Reporter.get()?.addBreadcrumb(
            category = breadcrumb.category,
            level = breadcrumb.level,
            message = breadcrumb.message,
            data = decodeJsonObject(breadcrumb.dataJson),
            timestampMs = breadcrumb.timestampMs,
        )
        callback(Result.success(Unit))
    }

    override fun captureError(
        error: CaptureErrorMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        Reporter.get()?.captureException(
            event = error.event,
            message = error.message,
            stackTrace = error.stackTrace,
            library = error.library,
        )
        callback(Result.success(Unit))
    }

    override fun setReporterUserId(userId: String?, callback: (Result<Unit>) -> Unit) {
        Reporter.get()?.setUserId(userId)
        callback(Result.success(Unit))
    }

    override fun flushReporter(callback: (Result<Unit>) -> Unit) {
        Reporter.get()?.flushPending()
        callback(Result.success(Unit))
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }


    private fun applyAndroidConfig(config: AndroidConfigMessage) {
        DetectorRegistry.configure(config.signingCertHashes, config.supportedStores)
    }

    private fun startMonitoringInternal(context: android.content.Context, intervalMs: Long) {
        stopMonitoringInternal()
        monitoringActive = true
        val executor = Executors.newSingleThreadScheduledExecutor { runnable ->
            Thread(runnable, "flutter-rasp-monitor").apply {
                isDaemon = true
                priority = Thread.NORM_PRIORITY - 1
            }
        }
        scheduledExecutor = executor
        monitoringFuture = executor.scheduleAtFixedRate({
            try {
                if (!monitoringActive) return@scheduleAtFixedRate
                val currentEnabled = enabledThreats
                val currentExitThreats = exitThreats
                val threats = DetectorRegistry.detectThreats(context, currentEnabled)
                if (threats.isNotEmpty()) {
                    if (currentExitThreats.isNotEmpty() && threats.any { it in currentExitThreats }) {
                        val matched = threats.filter { it in currentExitThreats }
                        logTermination(threats, matched)
                        terminateApp(matched)
                        return@scheduleAtFixedRate
                    }
                    val reportable = threats.filter { it !in currentExitThreats }
                    if (reportable.isNotEmpty()) {
                        Reporter.get()?.reportThreatDetected(reportable)
                        mainHandler.post {
                            flutterApi?.onThreatsDetected(reportable) {}
                        }
                    }
                }
            } catch (_: Throwable) {
                // Throwable: anything escaping cancels all future runs.
            }
        }, 0L, intervalMs, TimeUnit.MILLISECONDS)
    }

    private fun logTermination(detected: List<String>, matched: List<String>) {
        val separator = "!".repeat(60)
        Log.e(TAG, separator)
        Log.e(TAG, "  FLUTTER RASP — SECURITY VIOLATION DETECTED")
        Log.e(TAG, separator)
        Log.e(TAG, "  Detected threats : ${detected.joinToString(", ") { it.uppercase() }}")
        Log.e(TAG, "  Policy violation : ${matched.joinToString(", ") { it.uppercase() }}")
        Log.e(TAG, "  Action           : TERMINATING APP")
        Log.e(TAG, separator)
    }

    private fun terminateApp(matchedExitThreats: List<String>) {
        // Synchronous; the reporter caps itself at config.exitTimeoutMs.
        runCatching { Reporter.get()?.reportExitThreat(matchedExitThreats) }

        val currentActivity = activity
        if (currentActivity != null) {
            mainHandler.post {
                try {
                    currentActivity.finishAndRemoveTask()
                } catch (_: Exception) {
                    try { currentActivity.finishAffinity() } catch (_: Exception) {}
                }
                android.os.Process.killProcess(android.os.Process.myPid())
            }
        }

        Thread {
            Thread.sleep(500)
            Runtime.getRuntime().exit(1)
        }.start()
    }

    private fun stopMonitoringInternal() {
        monitoringActive = false
        monitoringFuture?.cancel(false)
        monitoringFuture = null
        scheduledExecutor?.shutdown()
        scheduledExecutor = null
    }

    private fun noContextFailure(): Result<Nothing> = Result.failure(
        FlutterError("NO_CONTEXT", "Application context is not available", null),
    )

    private fun decodeJsonObject(json: String): Map<String, Any?> {
        if (json.isEmpty()) return emptyMap()
        return runCatching {
            val obj = org.json.JSONObject(json)
            val map = mutableMapOf<String, Any?>()
            val keys = obj.keys()
            while (keys.hasNext()) {
                val k = keys.next()
                map[k] = obj.opt(k).takeUnless { it == org.json.JSONObject.NULL }
            }
            map.toMap()
        }.getOrDefault(emptyMap())
    }

    private fun ReporterConfigMessage.toCoreConfig() = ReporterConfig(
        endpoint = endpoint,
        headers = headers,
        hmacKey = hmacKey,
        pinnedCertPem = pinnedCertPem,
        exitTimeoutMs = exitTimeoutMs.coerceAtLeast(0L),
        httpTimeoutMs = httpTimeoutMs.toInt().coerceAtLeast(100),
        maxBreadcrumbs = maxBreadcrumbs.toInt().coerceAtLeast(1),
        maxPendingReports = maxPendingReports.toInt().coerceAtLeast(1),
        retryBackoffsMs = retryBackoffsMs.map { it.coerceAtLeast(100L) },
        captureFlutterErrors = captureFlutterErrors,
        capturePlatformErrors = capturePlatformErrors,
        captureExitThreats = captureExitThreats,
        captureDetectedThreats = captureDetectedThreats,
        userId = userId,
    )
}
