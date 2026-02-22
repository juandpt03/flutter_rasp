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
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class FlutterRaspPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    companion object {
        private const val TAG = "FlutterRASP"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var applicationContext: android.content.Context? = null
    @Volatile private var activity: Activity? = null
    @Volatile private var eventSink: EventChannel.EventSink? = null
    private val screenCaptureManager = ScreenCaptureManager()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var scheduledExecutor: ScheduledExecutorService? = null
    private var monitoringFuture: ScheduledFuture<*>? = null
    @Volatile private var enabledThreats: List<String>? = null
    @Volatile private var exitThreats: List<String> = emptyList()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.juandpt/flutter_rasp/methods")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.juandpt/flutter_rasp/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopMonitoringInternal()
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }

        when (call.method) {
            "startMonitoring" -> {
                val args = call.arguments as? Map<*, *>
                enabledThreats = (args?.get("enabledThreats") as? List<*>)?.filterIsInstance<String>()
                exitThreats = (args?.get("exitThreats") as? List<*>)?.filterIsInstance<String>() ?: emptyList()
                val interval = (args?.get("monitoringInterval") as? Number)?.toLong() ?: 10000L
                applyAndroidConfig(args)

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
                result.success(null)
            }
            "stopMonitoring" -> {
                stopMonitoringInternal()
                result.success(null)
            }
            "checkThreat" -> {
                val args = call.arguments as? Map<*, *>
                val threatName = args?.get("threatName") as? String
                if (threatName == null) {
                    result.error("INVALID_ARGUMENT", "threatName is required", null)
                    return
                }
                Thread {
                    val detected = DetectorRegistry.detect(threatName, context)
                    mainHandler.post { result.success(detected) }
                }.start()
            }
            "scanAll" -> {
                val args = call.arguments as? Map<*, *>
                val threats = (args?.get("enabledThreats") as? List<*>)?.filterIsInstance<String>()
                applyAndroidConfig(args)
                Thread {
                    val detected = DetectorRegistry.detectAll(context, threats)
                    mainHandler.post { result.success(detected) }
                }.start()
            }
            "blockScreenCapture" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("SCREEN_CAPTURE_NO_ACTIVITY", "No active Activity available to block screen capture", null)
                    return
                }
                val enabled = (call.arguments as? Map<*, *>)?.get("enabled") as? Boolean ?: false
                screenCaptureManager.block(currentActivity, enabled)
                result.success(null)
            }
            "isScreenCaptureBlocked" -> {
                result.success(screenCaptureManager.isBlocked())
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
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

    private fun applyAndroidConfig(args: Map<*, *>?) {
        val androidConfig = args?.get("androidConfig") as? Map<*, *> ?: return
        val hashes = (androidConfig["signingCertHashes"] as? List<*>)?.filterIsInstance<String>()
        val stores = (androidConfig["supportedStores"] as? List<*>)?.filterIsInstance<String>()
        DetectorRegistry.configure(hashes, stores)
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
                        mainHandler.post { eventSink?.success(reportable) }
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
