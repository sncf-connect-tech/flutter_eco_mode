//
//  DisposableStreamListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 02/03/2026.
//

import Flutter

protocol DisposableStreamListener {
    func register(binaryMessenger: FlutterBinaryMessenger)
    func dispose(binaryMessenger: FlutterBinaryMessenger)
}

/// Single source of truth for the Pigeon-generated event channel names, so
/// `dispose()` implementations don't each retype (and risk typo-ing) these
/// strings independently from the `register()` calls.
enum EcoModeEventChannels {
    private static let prefix = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel"

    static let batteryLevel = "\(prefix).batteryLevel"
    static let batteryState = "\(prefix).batteryState"
    static let batteryMode = "\(prefix).batteryMode"
    static let connectivity = "\(prefix).connectivity"
}
