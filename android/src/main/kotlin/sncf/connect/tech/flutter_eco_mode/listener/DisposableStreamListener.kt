package sncf.connect.tech.flutter_eco_mode.listener

import io.flutter.plugin.common.BinaryMessenger

interface DisposableStreamListener {
    fun register(binaryMessenger: BinaryMessenger)
    fun dispose(binaryMessenger: BinaryMessenger)
}

/**
 * Single source of truth for the Pigeon-generated event channel names, so
 * `dispose()` implementations don't each retype (and risk typo-ing) these
 * strings independently from the `register()` calls.
 */
internal object EcoModeEventChannels {
    private const val PREFIX = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel"

    const val BATTERY_LEVEL = "$PREFIX.batteryLevel"
    const val BATTERY_STATE = "$PREFIX.batteryState"
    const val BATTERY_MODE = "$PREFIX.batteryMode"
    const val CONNECTIVITY = "$PREFIX.connectivity"
}

