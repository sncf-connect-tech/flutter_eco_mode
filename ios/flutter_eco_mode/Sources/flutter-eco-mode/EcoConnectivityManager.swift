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
    static let shared = EcoConnectivityManager()
    
    private let monitor = NWPathMonitor()
    private var currentPath: NWPath?
    
    var onConnectivityChanged: ((Connectivity) -> Void)?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            let connectivity = self?.mapPathToConnectivity(path) ?? Connectivity(type: .unknown)
            self?.onConnectivityChanged?(connectivity)
        }
        let queue = DispatchQueue(label: "EcoConnectivityMonitor")
        monitor.start(queue: queue)
    }
    
    func getConnectivity() -> Connectivity {
        if let path = currentPath {
            return mapPathToConnectivity(path)
        }
        return Connectivity(type: .unknown)
    }
    
    private func mapPathToConnectivity(_ path: NWPath) -> Connectivity {
        let isLowQuality = path.isConstrained || path.isExpensive
        // Use -60 for good quality, -80 for low quality (threshold is -70 in Dart)
        let simulatedSignalStrength: Int64 = isLowQuality ? -80 : -60
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return Connectivity(type: .wifi, wifiSignalStrength: simulatedSignalStrength)
            } else if path.usesInterfaceType(.cellular) {
                return getDetailedMobileConnectivity()
            } else if path.usesInterfaceType(.wiredEthernet) {
                return Connectivity(type: .ethernet)
            }
        } else if path.status == .unsatisfied {
            return Connectivity(type: .none)
        }
        return Connectivity(type: .unknown)
    }
    
    private func getDetailedMobileConnectivity() -> Connectivity {
        var type: ConnectivityType = .unknown
        
        let networkInfo = CTTelephonyNetworkInfo()
        // On simulator or without a SIM card, serviceCurrentRadioAccessTechnology will be nil
        if let radioAccessTechnology = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            switch radioAccessTechnology {
            case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
                type = .mobile2g
            case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyeHRPD:
                type = .mobile3g
            case CTRadioAccessTechnologyLTE:
                type = .mobile4g
            default:
                if #available(iOS 14.1, *) {
                    if radioAccessTechnology == CTRadioAccessTechnologyNRNSA || radioAccessTechnology == CTRadioAccessTechnologyNR {
                        type = .mobile5g
                    }
                }
            }
        }
        
        return Connectivity(type: type)
    }
}
