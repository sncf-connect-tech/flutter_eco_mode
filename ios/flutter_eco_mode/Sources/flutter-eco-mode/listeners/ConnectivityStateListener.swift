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
    private var observerToken: UUID?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Connectivity>) {
        self.eventSink = sink
        
        // Declared before the closure so it can be captured by reference: the closure only runs
        // asynchronously (after this method returns), by which point `token` holds its final value.
        var token: UUID?
        token = EcoConnectivityManager.shared.addObserver { [weak self] connectivity in
            // Guard against a pending update from a previous (already cancelled) subscription
            // being delivered to this new subscription's eventSink.
            guard let self, self.observerToken == token else { return }
            self.sendUpdate(connectivity)
        }
        observerToken = token
        
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
        if let observerToken {
            EcoConnectivityManager.shared.removeObserver(observerToken)
        }
        observerToken = nil
    }
}
