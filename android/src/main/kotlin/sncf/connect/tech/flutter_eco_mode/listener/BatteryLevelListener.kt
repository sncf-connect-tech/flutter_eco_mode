package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.BatteryLevelStreamHandler
import sncf.connect.tech.flutter_eco_mode.EcoBatteryManager
import sncf.connect.tech.flutter_eco_mode.MessagesPigeonMethodCodec
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class BatteryLevelListener(
    private val ecoBatteryManager: EcoBatteryManager,
) : BatteryLevelStreamHandler(), DisposableStreamListener {
    private var batteryLevelEventSink: PigeonEventSink<Double>? = null
    private var batteryLevelReceiver: BroadcastReceiver? = null
    private var lastSentLevel: Double? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Double>) {
        batteryLevelEventSink = sink

        batteryLevelReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                sendBatteryLevel(intent)
            }
        }

        val stickyIntent = ecoBatteryManager.registerBatteryReceiver(batteryLevelReceiver)
        sendBatteryLevel(stickyIntent)
    }

    override fun onCancel(p0: Any?) {
        cleanUp()
    }

    override fun register(binaryMessenger: BinaryMessenger) = register(binaryMessenger, this)

    override fun dispose(binaryMessenger: BinaryMessenger) {
        cleanUp()

        EventChannel(binaryMessenger, EcoModeEventChannels.BATTERY_LEVEL, MessagesPigeonMethodCodec).setStreamHandler(null)
    }

    private fun cleanUp() {
        batteryLevelReceiver?.let { ecoBatteryManager.unregisterReceiver(it) }
        batteryLevelReceiver = null
        batteryLevelEventSink = null
        lastSentLevel = null
    }

    private fun sendBatteryLevel(intent: Intent?) {
        val batteryPct = ecoBatteryManager.parseLevel(intent)

        if (batteryPct != lastSentLevel) {
            lastSentLevel = batteryPct
            batteryLevelEventSink?.success(batteryPct)
        }
    }
}
