package sncf.connect.tech.flutter_eco_mode

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class FlutterEcoModePlugin : FlutterPlugin, EcoModeApi, EventChannel.StreamHandler {
    private lateinit var context: Context

    private val lowPowerModeEventChannel = "sncf.connect.tech/battery.isLowPowerMode"
    private var eventSink: EventChannel.EventSink? = null

    private var powerSavingReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        EcoModeApi.setUp(flutterPluginBinding.binaryMessenger, this)
        context = flutterPluginBinding.applicationContext
        EventChannel(flutterPluginBinding.binaryMessenger, lowPowerModeEventChannel).setStreamHandler(this)
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        EcoModeApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setupPowerSavingReceiver()
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        context.unregisterReceiver(powerSavingReceiver)
    }

    override fun getPlatformInfo(): String {
        val release: String = Build.VERSION.RELEASE
        val device: String = Build.DEVICE
        val hardware: String = Build.HARDWARE
        val product: String = Build.PRODUCT
        val type: String = Build.TYPE
        return "Android - $release - $device - $hardware - $product - $type"
    }

    override fun getBatteryLevel(): Double {
        val batteryStatus = getBatteryStatus()
        val batteryLevel: Double? = batteryStatus?.let { intent ->
            val level: Int = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale: Int = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            level * 100 / scale.toDouble()
        }
        return batteryLevel ?: 0.0
    }

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

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setupPowerSavingReceiver() {
        powerSavingReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                eventSink?.success(powerManager.isPowerSaveMode)
            }
        }
        val filter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        context.registerReceiver(powerSavingReceiver, filter)
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

    // TODO: not definitive, algo to update => to confirm
    override fun isLowEndDevice(): Boolean {
        var score = 0

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) score++
        if (getBatteryLevel() <= 10) score++
        if (getBatteryState() == BatteryState.DISCHARGING) score++
        if (isBatteryInLowPowerMode()) score++
        if (getTotalMemory() <= 1_000_000_000) score++
        if (getProcessorCount() <= 2) score++
        if (getTotalStorage() <= 16_000_000_000) score++

        return score >= 5
    }

    private fun getBatteryStatus(): Intent? {
        return IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { intentFilter ->
            context.registerReceiver(null, intentFilter)
        }
    }

    private fun convertBatteryState(state: Int): BatteryState {
        return when (state) {
            BatteryManager.BATTERY_STATUS_CHARGING -> BatteryState.CHARGING
            BatteryManager.BATTERY_STATUS_FULL -> BatteryState.FULL
            BatteryManager.BATTERY_STATUS_DISCHARGING, BatteryManager.BATTERY_STATUS_NOT_CHARGING -> BatteryState.DISCHARGING
            else -> BatteryState.UNKNOWN
        }
    }

    private fun convertThermalState(state: Int): ThermalState {
        return when (state) {
            PowerManager.THERMAL_STATUS_NONE -> ThermalState.SAFE
            PowerManager.THERMAL_STATUS_MODERATE, PowerManager.THERMAL_STATUS_LIGHT -> ThermalState.FAIR
            PowerManager.THERMAL_STATUS_SEVERE -> ThermalState.SERIOUS
            PowerManager.THERMAL_STATUS_CRITICAL, PowerManager.THERMAL_STATUS_EMERGENCY, PowerManager.THERMAL_STATUS_SHUTDOWN -> ThermalState.CRITICAL
            else -> ThermalState.UNKNOWN
        }
    }
}
