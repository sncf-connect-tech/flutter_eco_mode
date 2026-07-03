package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.BatteryModeStreamHandler
import sncf.connect.tech.flutter_eco_mode.EcoBatteryManager
import sncf.connect.tech.flutter_eco_mode.MessagesPigeonMethodCodec
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class PowerModeListener(
    private val ecoBatteryManager: EcoBatteryManager,
) : BatteryModeStreamHandler(), DisposableStreamListener {
    private var lowPowerModeEventSink: PigeonEventSink<Boolean>? = null
    private var powerSavingReceiver: BroadcastReceiver? = null
    private var lastPowerSaveMode: Boolean? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Boolean>) {
        lowPowerModeEventSink = sink

        powerSavingReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                sendPowerSaveUpdate(ecoBatteryManager.isLowPowerMode())
            }
        }

        ecoBatteryManager.registerPowerModeReceiver(powerSavingReceiver)
        sendPowerSaveUpdate(ecoBatteryManager.isLowPowerMode())
    }

    override fun onCancel(p0: Any?) {
        cleanUp()
    }

    override fun register(binaryMessenger: BinaryMessenger) = register(binaryMessenger, this)

    override fun dispose(binaryMessenger: BinaryMessenger) {
        cleanUp()

        EventChannel(binaryMessenger, EcoModeEventChannels.BATTERY_MODE, MessagesPigeonMethodCodec).setStreamHandler(null)
    }

    private fun cleanUp() {
        powerSavingReceiver?.let { ecoBatteryManager.unregisterReceiver(it) }
        powerSavingReceiver = null
        lowPowerModeEventSink = null
        lastPowerSaveMode = null
    }

    private fun sendPowerSaveUpdate(isPowerSaveMode: Boolean) {
        if (isPowerSaveMode != lastPowerSaveMode) {
            lastPowerSaveMode = isPowerSaveMode
            lowPowerModeEventSink?.success(isPowerSaveMode)
        }
    }
}
