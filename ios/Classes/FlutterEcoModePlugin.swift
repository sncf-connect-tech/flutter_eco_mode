import Flutter
import UIKit
import NotificationCenter

public class FlutterEcoModePlugin: NSObject, FlutterPlugin, EcoModeApi {
    func getEcoScore() throws -> Double? {
        //TODO vérifier l'OS, si en dessous de iphone 8 score --
        let nbrParams = 3
        var score = nbrParams
        
        let totalMemory = try getTotalMemory()
        let processorcount = try getProcessorCount()
        let totalStorage = try getTotalStorage()
        
        if (totalMemory <= 1_000_000_000) {  score = score - 1 }
        if (processorcount <= 2) {  score = score - 1 }
        if (totalStorage <= 16_000_000_000) {  score = score - 1 }
            
        return Double(score / nbrParams)
    }
    
    static let lowPowerModeEventChannelName = "sncf.connect.tech/battery.isLowPowerMode"
    static let batteryStateEventChannelName = "sncf.connect.tech/battery.state"
    static let batteryLevelEventChannelName = "sncf.connect.tech/battery.level"
    
    static public func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let api: EcoModeApi & NSObjectProtocol = FlutterEcoModePlugin.init()
        EcoModeApiSetup.setUp(binaryMessenger: messenger, api: api)
        
        FlutterEventChannel(name: lowPowerModeEventChannelName, binaryMessenger: messenger).setStreamHandler(PowerModeStreamHandler())
        
        FlutterEventChannel(name: batteryStateEventChannelName, binaryMessenger: messenger).setStreamHandler(BatteryStateStreamHandler())
        
        FlutterEventChannel(name: batteryLevelEventChannelName, binaryMessenger: messenger).setStreamHandler(BatteryLevelStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformInfo":
          result("iOS " + UIDevice.current.systemVersion)
        default:
          result(FlutterMethodNotImplemented)
        }
    }
    
    func getPlatformInfo() throws -> String {
        return "\(UIDevice.current.systemVersion) -!- \(UIDevice.current)"
    }
    
    func getBatteryLevel() throws -> Double {
        enableBatteryMonitoring()
        return Double(UIDevice.current.batteryLevel)
    }
    
    func getBatteryState() throws -> BatteryState {
        enableBatteryMonitoring()
        return convertBatteryState(state: UIDevice.current.batteryState)
    }
    
    func isBatteryInLowPowerMode() throws -> Bool {
        enableBatteryMonitoring()
        NSLog("battery low power mode: " + String(ProcessInfo.processInfo.isLowPowerModeEnabled))
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    func getThermalState() throws -> ThermalState {
        return convertThermalState(state: ProcessInfo.processInfo.thermalState)
    }
    
    func getProcessorCount() throws -> Int64 {
        return Int64(ProcessInfo.processInfo.processorCount)
    }
    
    func getTotalMemory() throws -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    func getFreeMemory() throws -> Int64 {
        var availabeRam: Int = 0
        if #available(iOS 13.0, *) {
            availabeRam = os_proc_available_memory()
        } else {
            // Fallback on earlier versions
        }
        return Int64(availabeRam)
    }
    
    func getTotalStorage() throws -> Int64 {
        var storage: Int64 = 0
        let fileURL: URL
        
        if #available(iOS 16.0, *) {
            fileURL = URL(filePath: NSHomeDirectory() as String)
        } else {
            fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        }
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            if let capacity = values.volumeTotalCapacity {
                storage = Int64(capacity)
                print("Total Capacity: \(capacity)")
            }
            return storage
        } catch {
            print("Error retrieving resource keys: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getFreeStorage() throws -> Int64 {
        var storage: Int64 = 0
        let fileURL: URL
        
        if #available(iOS 16.0, *) {
            fileURL = URL(filePath: NSHomeDirectory() as String)
        } else {
            fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        }
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                storage = Int64(capacity)
                print("Avaliable capacity for important usage: \(capacity)")
            }
            return storage
        } catch {
            print("Error retrieving capacity: \(error.localizedDescription)")
            throw error
        }
    }
    
    // ThermalState converter
    private func convertThermalState(state: ProcessInfo.ThermalState) -> ThermalState {
        switch state {
        case .nominal:
            return .safe
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .unknown
        }
    }
}

public class PowerModeStreamHandler: NSObject, FlutterStreamHandler {
    
    fileprivate var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        enableBatteryMonitoring()
        self.eventSink = events
        NotificationCenter.default.addObserver(self, selector: #selector(lowPowerModeChanged), name: .NSProcessInfoPowerStateDidChange, object: nil)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self, name: .NSProcessInfoPowerStateDidChange, object: nil)
        eventSink = nil
        return nil
    }
    
    @objc
    func lowPowerModeChanged() {
        self.eventSink?(ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
    
}

public class BatteryStateStreamHandler: NSObject, FlutterStreamHandler {
    
    fileprivate var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        enableBatteryMonitoring()
        self.eventSink = events
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateChanged(_:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        eventSink = nil
        return nil
    }
    
    @objc func batteryStateChanged(_ notification: Notification) {
        let batteryState = convertBatteryState(state: UIDevice.current.batteryState)
        self.eventSink?(batteryState)
    }
    
}

public class BatteryLevelStreamHandler: NSObject, FlutterStreamHandler {
    
    fileprivate var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        enableBatteryMonitoring()
        self.eventSink = events
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelChanged(_:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        eventSink = nil
        return nil
    }
    
    @objc func batteryLevelChanged(_ notification: Notification) {
        let batteryLevel = Double(UIDevice.current.batteryLevel)
        self.eventSink?(batteryLevel)
    }
    
}


private func convertBatteryState(state: UIDevice.BatteryState) -> BatteryState {
    switch state {
    case .charging:
        return .charging
    case .unplugged:
        return .discharging
    case .full:
        return .full
    case .unknown:
        return .unknown
    @unknown default:
        return .unknown
    }
}

private func enableBatteryMonitoring() {
    let device = UIDevice.current
    if !device.isBatteryMonitoringEnabled {
        device.isBatteryMonitoringEnabled = true
    }
}
