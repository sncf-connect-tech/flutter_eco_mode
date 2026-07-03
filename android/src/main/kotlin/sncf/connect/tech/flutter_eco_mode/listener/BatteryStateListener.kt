package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.BatteryState
import sncf.connect.tech.flutter_eco_mode.BatteryStateStreamHandler
import sncf.connect.tech.flutter_eco_mode.EcoBatteryManager
import sncf.connect.tech.flutter_eco_mode.MessagesPigeonMethodCodec
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class BatteryStateListener(
    private val ecoBatteryManager: EcoBatteryManager,
) : BatteryStateStreamHandler(), DisposableStreamListener {

    private var batteryStateEventSink: PigeonEventSink<BatteryState>? = null
    private var batteryStateReceiver: BroadcastReceiver? = null
    private var lastSentState: BatteryState? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<BatteryState>) {
        batteryStateEventSink = sink

        batteryStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                sendBatteryStatus(intent)
            }
        }

        val stickyIntent = ecoBatteryManager.registerBatteryReceiver(batteryStateReceiver)
        sendBatteryStatus(stickyIntent)
    }

    override fun onCancel(p0: Any?) {
        cleanUp()
    }

    override fun register(binaryMessenger: BinaryMessenger) = register(binaryMessenger, this)

    override fun dispose(binaryMessenger: BinaryMessenger) {
        cleanUp()

        EventChannel(binaryMessenger, EcoModeEventChannels.BATTERY_STATE, MessagesPigeonMethodCodec).setStreamHandler(null)
    }

    private fun cleanUp() {
        batteryStateReceiver?.let { ecoBatteryManager.unregisterReceiver(it) }
        batteryStateReceiver = null
        batteryStateEventSink = null
        lastSentState = null
    }

    private fun sendBatteryStatus(intent: Intent?) {
        val currentState = ecoBatteryManager.parseState(intent)

        if (currentState != lastSentState) {
            lastSentState = currentState
            batteryStateEventSink?.success(currentState)
        }
    }
}
