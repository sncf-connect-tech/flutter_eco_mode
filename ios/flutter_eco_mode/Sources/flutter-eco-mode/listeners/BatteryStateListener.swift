//
//  BatteryStateListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class BatteryStateListener: BatteryStateStreamHandler, DisposableStreamListener {
    private var eventSink: PigeonEventSink<BatteryState>?
    private var lastSentState: BatteryState?
    
    // MARK: - BatteryStateStreamHandler implementation

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<BatteryState>) {
        self.eventSink = sink
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }
    
    override func onCancel(withArguments arguments: Any?) {
        cleanUp()
    }
    
    // MARK: - DisposableStreamListener implementation
    
    func register(binaryMessenger: FlutterBinaryMessenger) {
        BatteryStateStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        FlutterEventChannel(name: EcoModeEventChannels.batteryState, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func batteryStateChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let currentState = EcoBatteryManager.shared.getBatteryState()
        
        guard currentState != lastSentState else { return }
        
        lastSentState = currentState
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?.success(currentState)
        }
    }
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentState = nil
    }
}
