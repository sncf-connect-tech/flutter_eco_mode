//
//  EcoModeImplem.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import UIKit

class EcoModeImplem: EcoModeApi, EcoModeComponent {
    private let totalMemoryMinimumThreshold = 1_000_000_000
    private let processorCountMinimumThreshold = 2
    private let totalStorageMinimumThreshold = 16_000_000_000
    
    private let _batteryLevelListener = BatteryLevelListener()
    private let _batteryStateListener = BatteryStateListener()
    private let _powerModeListener = PowerModeListener()
    private let _connectivityStateListener = ConnectivityStateListener()
    
    // MARK: - EcoModeComponent implementation
    
    var batteryLevelListener: DisposableStreamListener { _batteryLevelListener }
    var batteryStateListener: DisposableStreamListener { _batteryStateListener }
    var powerModeListener: DisposableStreamListener { _powerModeListener }
    var connectivityListener: DisposableStreamListener { _connectivityStateListener }
    
    func getEcoScore() throws -> Double {
        //TODO vérifier l'OS, si en dessous de iphone 8 score --
        let nbrParams = 3
        var score = nbrParams
        
        let totalMemory = try getTotalMemory()
        let processorcount = try getProcessorCount()
        let totalStorage = try getTotalStorage()
        
        if (totalMemory <= totalMemoryMinimumThreshold) {  score = score - 1 }
        if (processorcount <= processorCountMinimumThreshold) {  score = score - 1 }
        if (totalStorage <= totalStorageMinimumThreshold) {  score = score - 1 }
            
        return Double(score / nbrParams)
    }
    
    // MARK: - EcoModeApi implementation
    
    func getPlatformInfo() throws -> String {
        return "\(UIDevice.current.systemVersion) -!- \(UIDevice.current)"
    }
    
    func getBatteryLevel() throws -> Double {
        return EcoBatteryManager.shared.getBatteryLevel()
    }
    
    func getBatteryState() throws -> BatteryState {
        return EcoBatteryManager.shared.getBatteryState()
    }
    
    func isBatteryInLowPowerMode() throws -> Bool {
        return EcoBatteryManager.shared.isLowPowerMode()
    }
    
    func getThermalState() throws -> ThermalState {
        switch ProcessInfo.processInfo.thermalState {
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
    
    func getProcessorCount() throws -> Int64 {
        return Int64(ProcessInfo.processInfo.processorCount)
    }
    
    func getTotalMemory() throws -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    func getFreeMemory() throws -> Int64 {
        return Int64(os_proc_available_memory())
    }
    
    func getConnectivity(completion: @escaping (Result<Connectivity, Error>) -> Void) {
        completion(.success(Connectivity(type: .unknown)))
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
    
    func requestNetworkStatePermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func requestPhoneStatePermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
}
