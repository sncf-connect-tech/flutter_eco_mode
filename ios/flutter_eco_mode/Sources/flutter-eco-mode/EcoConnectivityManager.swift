//
//  EcoConnectivityManager.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 02/04/2026.
//

import Foundation
import Network
import CoreTelephony

class EcoConnectivityManager {
    // iOS does not expose a public API to read the real Wifi RSSI (dBm) without a
    // special Apple-granted entitlement (com.apple.developer.networking.wifi-info).
    // These values are therefore a best-effort simulation based on NWPath quality hints,
    // refined into 3 tiers instead of a binary good/bad approximation.
    private let goodWifiSignalStrength: Int64 = -60
    private let mediumWifiSignalStrength: Int64 = -70
    private let lowWifiSignalStrength: Int64 = -80

    static let shared = EcoConnectivityManager()
    
    private let monitor = NWPathMonitor()
    // Written on the NWPathMonitor background queue and read from other threads (e.g. the main
    // thread via getConnectivity()), so access is synchronized through observersQueue.
    private var _currentPath: NWPath?
    private var currentPath: NWPath? {
        get { observersQueue.sync { _currentPath } }
        set { observersQueue.sync { _currentPath = newValue } }
    }
    
    // CTTelephonyNetworkInfo MUST be created (and used) on the Main Thread to work and receive
    // callbacks. It is created asynchronously when initialization happens off the main thread,
    // so it is optional until that async initialization completes.
    private var networkInfo: CTTelephonyNetworkInfo?
    // Keep track of the current detailed mobile type (GPRS/LTE/5G...). Written from the main
    // thread (CTTelephonyNetworkInfo callbacks) and read from the NWPathMonitor background queue,
    // so access is protected by a lock to avoid data races.
    private let mobileTypeLock = NSLock()
    private var _currentMobileConnectivityType: ConnectivityType = .unknown
    private var currentMobileConnectivityType: ConnectivityType {
        get {
            mobileTypeLock.lock()
            defer { mobileTypeLock.unlock() }
            return _currentMobileConnectivityType
        }
        set {
            mobileTypeLock.lock()
            defer { mobileTypeLock.unlock() }
            _currentMobileConnectivityType = newValue
        }
    }
    
    // Multicast support: multiple independent listeners can register/unregister
    // without stepping on each other, unlike a single shared closure.
    private let observersQueue = DispatchQueue(label: "EcoConnectivityObservers")
    private var observers: [UUID: (Connectivity) -> Void] = [:]
    
    private init() {
        // Never use DispatchQueue.main.sync here: if this singleton is first accessed from a
        // background thread while the main thread is itself waiting on something that depends
        // on this initializer (e.g. blocked on the swift_once lock for `shared`), a sync dispatch
        // to main would deadlock. Instead, dispatch asynchronously and let networkInfo remain nil
        // until the async setup completes.
        if Thread.isMainThread {
            setUpNetworkInfo()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.setUpNetworkInfo()
            }
        }
        
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            let connectivity = self?.mapPathToConnectivity(path) ?? Connectivity(type: .unknown)
            self?.notifyObservers(connectivity)
        }
        let queue = DispatchQueue(label: "EcoConnectivityMonitor")
        monitor.start(queue: queue)
    }
    
    // Must be called on the main thread.
    private func setUpNetworkInfo() {
        let networkInfo = CTTelephonyNetworkInfo()
        self.networkInfo = networkInfo
        
        // Initial setup and capture of cellular technology
        currentMobileConnectivityType = resolveMobileConnectivityType()
        
        // Listen to radio technology changes on iOS
        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] _ in
            self?.updateMobileConnectivityTypeAsync()
        }
    }
    
    /// Registers a new observer and returns a token to be used with `removeObserver(_:)`.
    @discardableResult
    func addObserver(_ observer: @escaping (Connectivity) -> Void) -> UUID {
        let token = UUID()
        observersQueue.sync {
            observers[token] = observer
        }
        return token
    }
    
    /// Unregisters the observer identified by `token`. Only removes this observer,
    /// leaving every other registered listener untouched.
    func removeObserver(_ token: UUID) {
        observersQueue.sync {
            observers.removeValue(forKey: token)
        }
    }
    
    private func notifyObservers(_ connectivity: Connectivity) {
        let currentObservers: [(Connectivity) -> Void] = observersQueue.sync {
            Array(observers.values)
        }
        // Observers (e.g. ConnectivityStateListener) may touch main-thread-only state, so always
        // notify them on the main thread regardless of which queue triggered this update.
        DispatchQueue.main.async {
            currentObservers.forEach { $0(connectivity) }
        }
    }
    
    func getConnectivity() -> Connectivity {
        if let path = currentPath {
            return mapPathToConnectivity(path)
        }
        return Connectivity(type: .unknown)
    }
    
    private func updateMobileConnectivityTypeAsync() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentMobileConnectivityType = self.resolveMobileConnectivityType()
            if let path = self.currentPath {
                let connectivity = self.mapPathToConnectivity(path)
                self.notifyObservers(connectivity)
            }
        }
    }
    
    private func resolveMobileConnectivityType() -> ConnectivityType {
        // On simulator or without a SIM card, serviceCurrentRadioAccessTechnology will be nil
        guard let radioAccessTechnology = networkInfo?.serviceCurrentRadioAccessTechnology?.values.first else {
            return .unknown
        }
        
        switch radioAccessTechnology {
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            return .mobile2g
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyeHRPD:
            return .mobile3g
        case CTRadioAccessTechnologyLTE:
            return .mobile4g
        default:
            if #available(iOS 14.1, *) {
                if radioAccessTechnology == CTRadioAccessTechnologyNRNSA || radioAccessTechnology == CTRadioAccessTechnologyNR {
                    return .mobile5g
                }
            }
            return .unknown
        }
    }
    
    private func mapPathToConnectivity(_ path: NWPath) -> Connectivity {
        // isConstrained: Low Data Mode is on (user/system asked to limit data usage)
        // isExpensive: metered connection (e.g. cellular or Personal Hotspot)
        // Neither of these truly measures signal strength, but combining both gives a
        // finer 3-tier proxy than a single flag would (see comment on the properties above).
        let simulatedSignalStrength: Int64
        switch (path.isConstrained, path.isExpensive) {
        case (false, false):
            simulatedSignalStrength = goodWifiSignalStrength
        case (true, true):
            simulatedSignalStrength = lowWifiSignalStrength
        default:
            simulatedSignalStrength = mediumWifiSignalStrength
        }
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return Connectivity(type: .wifi, wifiSignalStrength: simulatedSignalStrength)
            } else if path.usesInterfaceType(.cellular) {
                return Connectivity(type: currentMobileConnectivityType)
            } else if path.usesInterfaceType(.wiredEthernet) {
                return Connectivity(type: .ethernet)
            }
        } else if path.status == .unsatisfied {
            return Connectivity(type: .none)
        }
        return Connectivity(type: .unknown)
    }
}
