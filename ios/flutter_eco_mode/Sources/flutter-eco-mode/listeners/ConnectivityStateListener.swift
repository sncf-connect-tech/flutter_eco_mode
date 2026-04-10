//
//  ConnectivityStateListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter
import Foundation

class ConnectivityStateListener: ConnectivityStreamHandler, DisposableStreamListener {
    private var eventSink: PigeonEventSink<Connectivity>?
    private var previousConnectivity: Connectivity?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Connectivity>) {
        self.eventSink = sink
        
        EcoConnectivityManager.shared.onConnectivityChanged = { [weak self] connectivity in
            self?.sendUpdate(connectivity)
        }
        
        // Send initial state
        sendUpdate(EcoConnectivityManager.shared.getConnectivity())
    }

    override func onCancel(withArguments arguments: Any?) {
        cleanUp()
    }
    
    func register(binaryMessenger: any FlutterBinaryMessenger) {
        ConnectivityStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: any FlutterBinaryMessenger) {
        cleanUp()
        
        let channelName = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel.connectivity"
        FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    private func sendUpdate(_ connectivity: Connectivity) {
        if let previousConnectivity = self.previousConnectivity {
            if previousConnectivity == connectivity {
                return
            }
        }
        
        self.previousConnectivity = connectivity
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?.success(connectivity)
        }
    }
    
    private func cleanUp() {
        eventSink = nil
        previousConnectivity = nil
        EcoConnectivityManager.shared.onConnectivityChanged = nil
    }
}
