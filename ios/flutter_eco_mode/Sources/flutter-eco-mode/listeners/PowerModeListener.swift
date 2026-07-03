//
//  PowerModeListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class PowerModeListener: BatteryModeStreamHandler, DisposableStreamListener {
    private var eventSink: PigeonEventSink<Bool>?
    private var lastSentPowerMode: Bool?
    
    // MARK: - BatteryModeStreamHandler implementation

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Bool>) {
        self.eventSink = sink
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    override func onCancel(withArguments arguments: Any?) {
        cleanUp()
    }
    
    // MARK: - DisposableStreamListener implementation
    
    func register(binaryMessenger: FlutterBinaryMessenger) {
        BatteryModeStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        FlutterEventChannel(name: EcoModeEventChannels.batteryMode, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func lowPowerModeChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let isLowPower = EcoBatteryManager.shared.isLowPowerMode()
        
        guard isLowPower != lastSentPowerMode else { return }
        
        lastSentPowerMode = isLowPower
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?.success(isLowPower)
        }
    }

    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentPowerMode = nil
    }
}
