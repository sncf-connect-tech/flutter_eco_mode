package listener

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.Intent.ACTION_BATTERY_CHANGED
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.BatteryManager.BATTERY_STATUS_CHARGING
import android.os.BatteryManager.BATTERY_STATUS_DISCHARGING
import android.os.BatteryManager.BATTERY_STATUS_FULL
import android.os.BatteryManager.BATTERY_STATUS_NOT_CHARGING
import android.os.Build
import android.os.PowerManager
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.BatteryState.CHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.DISCHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.FULL
import sncf.connect.tech.flutter_eco_mode.BatteryState.UNKNOWN

class PowerModeStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var lowPowerModeEventSink: EventChannel.EventSink? = null
    private var powerSavingReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        lowPowerModeEventSink = events

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setupPowerSavingReceiver()
        }
    }

    override fun onCancel(p0: Any?) {
        context.unregisterReceiver(powerSavingReceiver)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setupPowerSavingReceiver() {
        powerSavingReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                lowPowerModeEventSink?.success(powerManager.isPowerSaveMode)
            }
        }
        val filter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        context.registerReceiver(powerSavingReceiver, filter)
    }

}

class BatteryStateStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var batteryStateEventSink: EventChannel.EventSink? = null
    private var batteryStateReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        batteryStateEventSink = events

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            setupBatteryStateReceiver()
        }
    }

    override fun onCancel(p0: Any?) {
        context.unregisterReceiver(batteryStateReceiver)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setupBatteryStateReceiver() {
        batteryStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val event = when (intent?.action) {
                    ACTION_BATTERY_CHANGED ->
                        when (intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
                            BATTERY_STATUS_CHARGING -> CHARGING.name
                            BATTERY_STATUS_FULL -> FULL.name
                            BATTERY_STATUS_DISCHARGING, BATTERY_STATUS_NOT_CHARGING -> DISCHARGING.name
                            else -> UNKNOWN.name
                        }

                    else -> DISCHARGING.name
                }
                batteryStateEventSink?.success(event)
            }
        }
        val filterBatteryState = IntentFilter()
        filterBatteryState.addAction(ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryStateReceiver, filterBatteryState)
    }

}

class BatteryLevelStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var batteryLevelEventSink: EventChannel.EventSink? = null
    private var batteryLevelReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        batteryLevelEventSink = events

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setupBatteryLevelReceiver()
        }
    }

    override fun onCancel(p0: Any?) {
        context.unregisterReceiver(batteryLevelReceiver)
    }


    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setupBatteryLevelReceiver() {

        batteryLevelReceiver = object : BroadcastReceiver() {

            override fun onReceive(context: Context, intent: Intent?) {
                val batteryPct = intent?.let { i ->
                    val level: Int = i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale: Int = i.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    level * 100 / scale.toFloat()
                }
                batteryLevelEventSink?.success(batteryPct?.toDouble())
            }
        }
        val filter = IntentFilter(ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryLevelReceiver, filter)

    }

}