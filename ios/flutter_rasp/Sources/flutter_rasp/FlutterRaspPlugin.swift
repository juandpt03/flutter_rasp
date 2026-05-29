import Flutter
import FlutterRaspCore
import UIKit

public class FlutterRaspPlugin: NSObject, FlutterPlugin, FlutterRaspHostApi {

    private let monitoringQueue = DispatchQueue(label: "com.juandpt.flutter_rasp.monitoring", qos: .utility)
    private let screenCaptureManager = ScreenCaptureManager.shared
    private var flutterApi: FlutterRaspFlutterApi?
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
    private var _isMonitoringActive: Bool = false
    private var isMonitoringActive: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _isMonitoringActive }
        set { stateLock.lock(); defer { stateLock.unlock() }; _isMonitoringActive = newValue }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterRaspPlugin()
        FlutterRaspHostApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: instance
        )
        instance.flutterApi = FlutterRaspFlutterApi(
            binaryMessenger: registrar.messenger()
        )
    }


    func startMonitoring(config: RaspConfigMessage, completion: @escaping (Result<Void, Error>) -> Void) {
        enabledThreats = config.enabledThreats
        exitThreats = config.exitThreats
        let interval = config.monitoringIntervalMs

        if let ios = config.iosConfig {
            applyIosConfig(ios)
        }
        Reporter.shared?.setActivePolicy(exitThreats: config.exitThreats)
        DetectorRegistry.shared.clearCache()

        let immediateThreats = DetectorRegistry.shared.detectThreats(enabledThreats: enabledThreats)
        let currentExitThreats = exitThreats
        if !immediateThreats.isEmpty && !currentExitThreats.isEmpty &&
            immediateThreats.contains(where: { currentExitThreats.contains($0) }) {
            let matched = immediateThreats.filter { currentExitThreats.contains($0) }
            logTermination(detected: immediateThreats, matched: matched)
            completion(.success(()))
            monitoringQueue.async { [weak self] in
                self?.terminateApp(matchedExitThreats: matched)
            }
            return
        }

        if !immediateThreats.isEmpty {
            let reportable = immediateThreats.filter { !currentExitThreats.contains($0) }
            if !reportable.isEmpty {
                Reporter.shared?.reportThreatDetected(reportable)
                DispatchQueue.main.async { [weak self] in
                    self?.flutterApi?.onThreatsDetected(threats: reportable) { _ in }
                }
            }
        }

        cancelTimer()
        monitoringInterval = TimeInterval(interval) / 1000.0
        isMonitoringActive = true
        startMonitoringTimer()
        monitoringQueue.async { [weak self] in
            self?.performMonitoringScan()
        }
        addLifecycleObservers()
        completion(.success(()))
    }

    func stopMonitoring(completion: @escaping (Result<Void, Error>) -> Void) {
        isMonitoringActive = false
        cancelTimer()
        enabledThreats = nil
        exitThreats = []
        removeLifecycleObservers()
        completion(.success(()))
    }

    func checkThreat(threatName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        monitoringQueue.async {
            let detected = DetectorRegistry.shared.detect(threatName: threatName)
            DispatchQueue.main.async {
                completion(.success(detected))
            }
        }
    }

    func scanAll(enabledThreats: [String], completion: @escaping (Result<ScanResultMessage, Error>) -> Void) {
        let threats = enabledThreats.isEmpty ? nil : enabledThreats
        monitoringQueue.async {
            let detected = DetectorRegistry.shared.detectAll(enabledThreats: threats)
            let entries = detected.map { (name, value) in
                ThreatResultEntry(threatName: name, detected: value)
            }
            let message = ScanResultMessage(results: entries)
            DispatchQueue.main.async {
                completion(.success(message))
            }
        }
    }

    func blockScreenCapture(enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        screenCaptureManager.block(enabled)
        completion(.success(()))
    }

    func isScreenCaptureBlocked(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(screenCaptureManager.getIsBlocked()))
    }


    func initReporter(
        config: ReporterConfigMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let coreConfig = ReporterConfig(
            endpoint: config.endpoint,
            headers: config.headers,
            hmacKey: config.hmacKey,
            pinnedCertPem: config.pinnedCertPem.flatMap { Data($0.data) },
            exitTimeoutMs: max(0, Int(config.exitTimeoutMs)),
            httpTimeoutMs: max(100, Int(config.httpTimeoutMs)),
            maxBreadcrumbs: max(1, Int(config.maxBreadcrumbs)),
            maxPendingReports: max(1, Int(config.maxPendingReports)),
            retryBackoffsMs: config.retryBackoffsMs.map { max(100, Int($0)) },
            captureFlutterErrors: config.captureFlutterErrors,
            capturePlatformErrors: config.capturePlatformErrors,
            captureExitThreats: config.captureExitThreats,
            captureDetectedThreats: config.captureDetectedThreats,
            userId: config.userId
        )
        Reporter.initShared(config: coreConfig)
        completion(.success(()))
    }

    func disposeReporter(completion: @escaping (Result<Void, Error>) -> Void) {
        Reporter.disposeShared()
        completion(.success(()))
    }

    func addBreadcrumb(
        breadcrumb: BreadcrumbMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let data = decodeJsonObject(breadcrumb.dataJson)
        Reporter.shared?.addBreadcrumb(
            category: breadcrumb.category,
            level: breadcrumb.level,
            message: breadcrumb.message,
            data: data,
            timestampMs: breadcrumb.timestampMs
        )
        completion(.success(()))
    }

    func captureError(
        error: CaptureErrorMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Reporter.shared?.captureException(
            event: error.event,
            message: error.message,
            stackTrace: error.stackTrace,
            library: error.library
        )
        completion(.success(()))
    }

    func setReporterUserId(userId: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        Reporter.shared?.setUserId(userId)
        completion(.success(()))
    }

    func flushReporter(completion: @escaping (Result<Void, Error>) -> Void) {
        Reporter.shared?.flushPending()
        completion(.success(()))
    }


    private func applyIosConfig(_ config: IosConfigMessage) {
        DetectorRegistry.shared.configure(teamId: config.teamId, bundleIds: config.bundleIds)
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

    private func terminateApp(matchedExitThreats: [String]) {
        // Synchronous; Reporter blocks for at most config.exitTimeoutMs.
        Reporter.shared?.reportExitThreat(matched: matchedExitThreats)
        exit(1)
    }

    private func performMonitoringScan() {
        guard isMonitoringActive else { return }

        let threats = DetectorRegistry.shared.detectThreats(enabledThreats: enabledThreats)
        if !threats.isEmpty {
            let currentExitThreats = exitThreats
            if !currentExitThreats.isEmpty && threats.contains(where: { currentExitThreats.contains($0) }) {
                let matched = threats.filter { currentExitThreats.contains($0) }
                logTermination(detected: threats, matched: matched)
                terminateApp(matchedExitThreats: matched)
                return
            }
            let reportable = threats.filter { !currentExitThreats.contains($0) }
            if !reportable.isEmpty {
                Reporter.shared?.reportThreatDetected(reportable)
                DispatchQueue.main.async { [weak self] in
                    self?.flutterApi?.onThreatsDetected(threats: reportable) { _ in }
                }
            }
        }
    }

    private func startMonitoringTimer() {
        let timer = DispatchSource.makeTimerSource(queue: monitoringQueue)
        timer.schedule(
            deadline: .now() + monitoringInterval,
            repeating: monitoringInterval,
            leeway: .milliseconds(100)
        )
        timer.setEventHandler { [weak self] in
            self?.performMonitoringScan()
        }
        monitoringTimer = timer
        timer.resume()
    }

    private func cancelTimer() {
        monitoringTimer?.cancel()
        monitoringTimer = nil
    }

    private func addLifecycleObservers() {
        removeLifecycleObservers()
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
        guard isMonitoringActive else { return }
        DetectorRegistry.shared.clearCache()
        cancelTimer()
        startMonitoringTimer()
        monitoringQueue.async { [weak self] in
            self?.performMonitoringScan()
        }
    }

    @objc private func appWillResignActive() {
        cancelTimer()
    }

    private func decodeJsonObject(_ json: String) -> [String: Any] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return [:] }
        return dict
    }
}
