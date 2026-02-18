import Flutter
import UIKit

public class FlutterRaspPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private let sinkQueue = DispatchQueue(label: "com.juandpt.flutter_rasp.sink")
    private let monitoringQueue = DispatchQueue(label: "com.juandpt.flutter_rasp.monitoring", qos: .utility)
    private var eventSink: FlutterEventSink?
    private let screenCaptureManager = ScreenCaptureManager()
    private var monitoringTimer: DispatchSourceTimer?
    private let stateLock = NSLock()
    private var _enabledThreats: [String]?
    private var enabledThreats: [String]? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _enabledThreats }
        set { stateLock.lock(); defer { stateLock.unlock() }; _enabledThreats = newValue }
    }
    private var _exitThreats: [String] = []
    private var exitThreats: [String] {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _exitThreats }
        set { stateLock.lock(); defer { stateLock.unlock() }; _exitThreats = newValue }
    }
    private var monitoringInterval: TimeInterval = 10.0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.juandpt/flutter_rasp/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.juandpt/flutter_rasp/events",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterRaspPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMonitoring":
            handleStartMonitoring(call.arguments, result: result)
        case "stopMonitoring":
            handleStopMonitoring(result: result)
        case "checkThreat":
            handleCheckThreat(call.arguments, result: result)
        case "scanAll":
            handleScanAll(call.arguments, result: result)
        case "blockScreenCapture":
            handleBlockScreenCapture(call.arguments, result: result)
        case "isScreenCaptureBlocked":
            result(screenCaptureManager.getIsBlocked())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sinkQueue.sync { eventSink = events }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sinkQueue.sync { eventSink = nil }
        return nil
    }

    private func handleStartMonitoring(_ arguments: Any?, result: FlutterResult) {
        let args = arguments as? [String: Any]
        enabledThreats = args?["enabledThreats"] as? [String]
        exitThreats = (args?["exitThreats"] as? [String]) ?? []
        let interval = (args?["monitoringInterval"] as? Int ?? 10000)

        applyIosConfig(args)

        let immediateThreats = DetectorRegistry.shared.detectThreats(enabledThreats: enabledThreats)
        let currentExitThreats = exitThreats
        if !immediateThreats.isEmpty && !currentExitThreats.isEmpty &&
            immediateThreats.contains(where: { currentExitThreats.contains($0) }) {
            let matched = immediateThreats.filter { currentExitThreats.contains($0) }
            logTermination(detected: immediateThreats, matched: matched)
            exit(1)
        }

        stopMonitoringInternal()
        monitoringInterval = TimeInterval(interval) / 1000.0
        startMonitoringTimer()
        monitoringQueue.async { [weak self] in
            self?.performMonitoringScan()
        }
        addLifecycleObservers()
        result(nil)
    }

    private func handleStopMonitoring(result: FlutterResult) {
        stopMonitoringInternal()
        removeLifecycleObservers()
        result(nil)
    }

    private func handleCheckThreat(_ arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let threatName = args["threatName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "threatName is required", details: nil))
            return
        }
        monitoringQueue.async {
            let detected = DetectorRegistry.shared.detect(threatName: threatName)
            DispatchQueue.main.async {
                result(detected)
            }
        }
    }

    private func handleScanAll(_ arguments: Any?, result: @escaping FlutterResult) {
        let args = arguments as? [String: Any]
        let threats = args?["enabledThreats"] as? [String]
        applyIosConfig(args)
        monitoringQueue.async {
            let detected = DetectorRegistry.shared.detectAll(enabledThreats: threats)
            DispatchQueue.main.async {
                result(detected)
            }
        }
    }

    private func handleBlockScreenCapture(_ arguments: Any?, result: FlutterResult) {
        let args = arguments as? [String: Any]
        let enabled = args?["enabled"] as? Bool ?? false
        screenCaptureManager.block(enabled)
        result(nil)
    }

    private func applyIosConfig(_ args: [String: Any]?) {
        guard let iosConfig = args?["iosConfig"] as? [String: Any] else { return }
        let teamId = iosConfig["teamId"] as? String
        let bundleIds = iosConfig["bundleIds"] as? [String]
        DetectorRegistry.shared.configure(teamId: teamId, bundleIds: bundleIds)
    }

    private func logTermination(detected: [String], matched: [String]) {
        let separator = String(repeating: "!", count: 60)
        NSLog("[FlutterRASP] %@", separator)
        NSLog("[FlutterRASP]   FLUTTER RASP — SECURITY VIOLATION DETECTED")
        NSLog("[FlutterRASP] %@", separator)
        NSLog("[FlutterRASP]   Detected threats : %@", detected.map { $0.uppercased() }.joined(separator: ", "))
        NSLog("[FlutterRASP]   Policy violation : %@", matched.map { $0.uppercased() }.joined(separator: ", "))
        NSLog("[FlutterRASP]   Action           : TERMINATING APP")
        NSLog("[FlutterRASP] %@", separator)
    }

    private func performMonitoringScan() {
        let threats = DetectorRegistry.shared.detectThreats(enabledThreats: enabledThreats)
        if !threats.isEmpty {
            let currentExitThreats = exitThreats
            if !currentExitThreats.isEmpty && threats.contains(where: { currentExitThreats.contains($0) }) {
                let matched = threats.filter { currentExitThreats.contains($0) }
                logTermination(detected: threats, matched: matched)
                exit(1)
            }
            let reportable = threats.filter { !currentExitThreats.contains($0) }
            if !reportable.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.sinkQueue.sync {
                        self?.eventSink?(reportable)
                    }
                }
            }
        }
    }

    private func startMonitoringTimer() {
        let timer = DispatchSource.makeTimerSource(queue: monitoringQueue)
        timer.schedule(
            deadline: .now() + monitoringInterval,
            repeating: monitoringInterval
        )
        timer.setEventHandler { [weak self] in
            self?.performMonitoringScan()
        }
        monitoringTimer = timer
        timer.resume()
    }

    private func stopMonitoringInternal() {
        monitoringTimer?.cancel()
        monitoringTimer = nil
        enabledThreats = nil
        exitThreats = []
    }

    private func addLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    private func removeLifecycleObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        if enabledThreats != nil {
            monitoringTimer?.cancel()
            monitoringTimer = nil
            startMonitoringTimer()
            monitoringQueue.async { [weak self] in
                self?.performMonitoringScan()
            }
        }
    }

    @objc private func appWillResignActive() {
        monitoringTimer?.cancel()
        monitoringTimer = nil
    }
}
