package com.juandpt.flutter_rasp

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.juandpt.flutter_rasp_core.DetectorRegistry
import com.juandpt.flutter_rasp_core.ScreenCaptureManager
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

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        FlutterRaspHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = FlutterRaspFlutterApi(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FlutterRaspHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        stopMonitoringInternal()
        applicationContext = null
    }

    // ── HostApi ────────────────────────────────────────────────

    override fun startMonitoring(config: RaspConfigMessage, callback: (Result<Unit>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(Result.failure(FlutterError("NO_CONTEXT", "Application context is not available", null)))
            return
        }

        enabledThreats = config.enabledThreats
        exitThreats = config.exitThreats
        val interval = config.monitoringIntervalMs.toLong()
        config.androidConfig?.let { applyAndroidConfig(it) }

        val immediateThreats = DetectorRegistry.detectThreats(context, enabledThreats)
        val currentExitThreats = exitThreats
        if (immediateThreats.isNotEmpty() && currentExitThreats.isNotEmpty() &&
            immediateThreats.any { it in currentExitThreats }) {
            val matched = immediateThreats.filter { it in currentExitThreats }
            logTermination(immediateThreats, matched)
            terminateApp()
            return
        }

        startMonitoringInternal(context, interval)
        callback(Result.success(Unit))
    }

    override fun stopMonitoring(callback: (Result<Unit>) -> Unit) {
        stopMonitoringInternal()
        callback(Result.success(Unit))
    }

    override fun checkThreat(threatName: String, callback: (Result<Boolean>) -> Unit) {
        val context = applicationContext
        if (context == null) {
            callback(Result.failure(FlutterError("NO_CONTEXT", "Application context is not available", null)))
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
            callback(Result.failure(FlutterError("NO_CONTEXT", "Application context is not available", null)))
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
            callback(Result.failure(FlutterError("SCREEN_CAPTURE_NO_ACTIVITY", "No active Activity available to block screen capture", null)))
            return
        }
        screenCaptureManager.block(currentActivity, enabled)
        callback(Result.success(Unit))
    }

    override fun isScreenCaptureBlocked(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(screenCaptureManager.isBlocked()))
    }

    // ── ActivityAware ─────────────────────────────────────────

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

    // ── Internal ──────────────────────────────────────────────

    private fun applyAndroidConfig(config: AndroidConfigMessage) {
        DetectorRegistry.configure(config.signingCertHashes, config.supportedStores)
    }

    private fun startMonitoringInternal(context: android.content.Context, intervalMs: Long) {
        stopMonitoringInternal()
        val executor = Executors.newSingleThreadScheduledExecutor { runnable ->
            Thread(runnable, "flutter-rasp-monitor").apply { isDaemon = true }
        }
        scheduledExecutor = executor
        monitoringFuture = executor.scheduleAtFixedRate({
            try {
                val threats = DetectorRegistry.detectThreats(context, enabledThreats)
                if (threats.isNotEmpty()) {
                    val currentExitThreats = exitThreats
                    if (currentExitThreats.isNotEmpty() && threats.any { it in currentExitThreats }) {
                        val matched = threats.filter { it in currentExitThreats }
                        logTermination(threats, matched)
                        terminateApp()
                        return@scheduleAtFixedRate
                    }
                    val reportable = threats.filter { it !in currentExitThreats }
                    if (reportable.isNotEmpty()) {
                        mainHandler.post {
                            flutterApi?.onThreatsDetected(reportable) {}
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }, intervalMs, intervalMs, TimeUnit.MILLISECONDS)
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

    private fun terminateApp() {
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
        monitoringFuture?.cancel(false)
        monitoringFuture = null
        scheduledExecutor?.shutdown()
        scheduledExecutor = null
        enabledThreats = null
        exitThreats = emptyList()
    }
}
