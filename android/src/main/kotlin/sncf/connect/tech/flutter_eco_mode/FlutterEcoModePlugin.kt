package sncf.connect.tech.flutter_eco_mode

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
import android.os.Environment
import android.os.PowerManager
import android.os.PowerManager.THERMAL_STATUS_CRITICAL
import android.os.PowerManager.THERMAL_STATUS_EMERGENCY
import android.os.PowerManager.THERMAL_STATUS_LIGHT
import android.os.PowerManager.THERMAL_STATUS_MODERATE
import android.os.PowerManager.THERMAL_STATUS_NONE
import android.os.PowerManager.THERMAL_STATUS_SEVERE
import android.os.PowerManager.THERMAL_STATUS_SHUTDOWN
import android.os.StatFs
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.BatteryState.CHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.DISCHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.FULL
import sncf.connect.tech.flutter_eco_mode.BatteryState.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.ThermalState.CRITICAL
import sncf.connect.tech.flutter_eco_mode.ThermalState.FAIR
import sncf.connect.tech.flutter_eco_mode.ThermalState.SAFE
import sncf.connect.tech.flutter_eco_mode.ThermalState.SERIOUS


class FlutterEcoModePlugin : FlutterPlugin, EcoModeApi {
    private lateinit var context: Context

    private val lowPowerModeEventChannel = "sncf.connect.tech/battery.isLowPowerMode"
    private val batteryStateEventChannel = "sncf.connect.tech/battery.state"
    private val batteryLevelEventChannel = "sncf.connect.tech/battery.level"

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        EcoModeApi.setUp(flutterPluginBinding.binaryMessenger, this)
        context = flutterPluginBinding.applicationContext
        EventChannel(
            flutterPluginBinding.binaryMessenger,
            lowPowerModeEventChannel,
        ).setStreamHandler(PowerModeStreamHandler(context))
        EventChannel(
            flutterPluginBinding.binaryMessenger,
            batteryStateEventChannel,
        ).setStreamHandler(BatteryStateStreamHandler(context))
        EventChannel(
            flutterPluginBinding.binaryMessenger,
            batteryLevelEventChannel,
        ).setStreamHandler(BatteryLevelStreamHandler(context))
    }


    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        EcoModeApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    override fun getPlatformInfo(): String {
        val release: String = Build.VERSION.RELEASE
        val device: String = Build.DEVICE
        val hardware: String = Build.HARDWARE
        val product: String = Build.PRODUCT
        val type: String = Build.TYPE
        return "Android - $release - $device - $hardware - $product - $type"
    }

    override fun getBatteryLevel(): Double = getBatteryLevel(getBatteryStatus())
    private fun getBatteryLevel(intent: Intent?): Double = intent?.let {
        val level: Int = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale: Int = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        level * 100 / scale.toDouble()
    } ?: 0.0

    override fun getBatteryState(): BatteryState {
        val batteryStatus = getBatteryStatus()
        val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return convertBatteryState(status)
    }

    override fun isBatteryInLowPowerMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            return powerManager.isPowerSaveMode
        }
        return false // can't return null so we return false for older versions
    }

    override fun getThermalState(): ThermalState {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            return convertThermalState(powerManager.currentThermalStatus)
        }
        return ThermalState.UNKNOWN
    }

    override fun getProcessorCount(): Long {
        return Runtime.getRuntime().availableProcessors().toLong()
        // TODO: check if it returns the total of cores
    }

    /// MEMORY
    override fun getTotalMemory(): Long {
        return Runtime.getRuntime().totalMemory()
    }

    override fun getFreeMemory(): Long {
        return Runtime.getRuntime().freeMemory()
    }

    /// STORAGE
    override fun getTotalStorage(): Long {
        val statFs = StatFs(Environment.getExternalStorageDirectory().absolutePath)
        val blockSizeLong = statFs.blockSizeLong
        val totalBlocksLong = statFs.blockCountLong
        return blockSizeLong * totalBlocksLong
    }

    override fun getFreeStorage(): Long {
        val statFs = StatFs(Environment.getExternalStorageDirectory().absolutePath)
        val blockSizeLong = statFs.blockSizeLong
        val availableBlocksLong = statFs.availableBlocksLong
        return blockSizeLong * availableBlocksLong
    }

    override fun getEcoScore(): Double {
        val nbrParams = 4.0
        var score = nbrParams

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) score--
        if (getTotalMemory() <= 1_000_000_000) score--
        if (getProcessorCount() <= 2) score--
        if (getTotalStorage() <= 16_000_000_000) score--

        return score / nbrParams
    }

    private fun getBatteryStatus(): Intent? {
        return IntentFilter(ACTION_BATTERY_CHANGED).let { intentFilter ->
            context.registerReceiver(null, intentFilter)
        }
    }

    private fun convertBatteryState(state: Int): BatteryState {
        return when (state) {
            BATTERY_STATUS_CHARGING -> CHARGING
            BATTERY_STATUS_FULL -> FULL
            BATTERY_STATUS_DISCHARGING, BATTERY_STATUS_NOT_CHARGING -> DISCHARGING
            else -> UNKNOWN
        }
    }

    private fun convertThermalState(state: Int): ThermalState {
        return when (state) {
            THERMAL_STATUS_NONE -> SAFE
            THERMAL_STATUS_MODERATE, THERMAL_STATUS_LIGHT -> FAIR
            THERMAL_STATUS_SEVERE -> SERIOUS
            THERMAL_STATUS_CRITICAL, THERMAL_STATUS_EMERGENCY, THERMAL_STATUS_SHUTDOWN -> CRITICAL
            else -> ThermalState.UNKNOWN
        }
    }
}

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
