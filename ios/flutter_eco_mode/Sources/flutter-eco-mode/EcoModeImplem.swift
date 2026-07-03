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
        let nbrParams = 3
        var score = nbrParams
        
        let totalMemory = try getTotalMemory()
        let processorcount = try getProcessorCount()
        let totalStorage = try getTotalStorage()
        
        if (totalMemory <= totalMemoryMinimumThreshold) {  score = score - 1 }
        if (processorcount <= processorCountMinimumThreshold) {  score = score - 1 }
        if (totalStorage <= totalStorageMinimumThreshold) {  score = score - 1 }
            
        return Double(score) / Double(nbrParams)
    }
    
    // MARK: - EcoModeApi implementation
    
    func getPlatformInfo() throws -> String {
        return "iOS - \(UIDevice.current.systemVersion) - \(UIDevice.current.model) - \(UIDevice.current.name)"
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
        completion(.success(EcoConnectivityManager.shared.getConnectivity()))
    }
    
    func getTotalStorage() throws -> Int64 {
        let fileURL: URL
        
        if #available(iOS 16.0, *) {
            fileURL = URL(filePath: NSHomeDirectory() as String)
        } else {
            fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        }
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            guard let capacity = values.volumeTotalCapacity else {
                throw PigeonError(
                    code: "STORAGE_ERROR",
                    message: "Total storage capacity is unavailable for this volume.",
                    details: nil
                )
            }
            return Int64(capacity)
        } catch let error as PigeonError {
            throw error
        } catch {
            throw PigeonError(
                code: "STORAGE_ERROR",
                message: "Error while retrieving total storage: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    func getFreeStorage() throws -> Int64 {
        let fileURL: URL
        
        if #available(iOS 16.0, *) {
            fileURL = URL(filePath: NSHomeDirectory() as String)
        } else {
            fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        }
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
                throw PigeonError(
                    code: "STORAGE_ERROR",
                    message: "Free storage capacity is unavailable for this volume.",
                    details: nil
                )
            }
            return Int64(capacity)
        } catch let error as PigeonError {
            throw error
        } catch {
            throw PigeonError(
                code: "STORAGE_ERROR",
                message: "Error while retrieving free storage: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    func requestNetworkStatePermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func requestPhoneStatePermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
}
