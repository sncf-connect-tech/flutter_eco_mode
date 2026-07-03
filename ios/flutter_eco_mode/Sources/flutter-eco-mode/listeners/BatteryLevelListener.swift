//
//  BatteryLevelListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class BatteryLevelListener: BatteryLevelStreamHandler, DisposableStreamListener {
    private var eventSink: PigeonEventSink<Double>?
    private var lastSentLevel: Double?
    
    // MARK: - BatteryLevelStreamHandler implementation

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Double>) {
        self.eventSink = sink
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
    }
    
    override func onCancel(withArguments arguments: Any?) {
        cleanUp()
    }
    
    // MARK: - DisposableStreamListener implementation
    
    func register(binaryMessenger: FlutterBinaryMessenger) {
        BatteryLevelStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        FlutterEventChannel(name: EcoModeEventChannels.batteryLevel, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func batteryLevelChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let currentLevel = EcoBatteryManager.shared.getBatteryLevel()
        
        guard currentLevel != lastSentLevel else { return }
        
        lastSentLevel = currentLevel
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?.success(currentLevel)
        }
    }
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentLevel = nil
    }
}
