package sncf.connect.tech.flutter_eco_mode

import android.app.ActivityManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import sncf.connect.tech.flutter_eco_mode.listener.BatteryLevelListener
import sncf.connect.tech.flutter_eco_mode.listener.BatteryStateListener
import sncf.connect.tech.flutter_eco_mode.listener.ConnectivityStateListener
import sncf.connect.tech.flutter_eco_mode.listener.DisposableStreamListener
import sncf.connect.tech.flutter_eco_mode.listener.PowerModeListener

class EcoModeImplem(
    private val pluginScope: CoroutineScope,
    private val context: Context,
) : EcoModeApi, FlutterEcoModePlugin.ActivityComponent {
    companion object {
        private const val TOTAL_MEMORY_MINIMUM_THRESHOLD = 1_000_000_000
        private const val PROCESSOR_COUNT_MINIMUM_THRESHOLD = 2
        private const val TOTAL_STORAGE_MINIMUM_THRESHOLD = 16_000_000_000
    }

    private val ecoBatteryManager = EcoBatteryManager(context)
    private val permissionHandler = PermissionHandler()
    private val batteryLevelListener = BatteryLevelListener(ecoBatteryManager)
    private val batteryStateListener = BatteryStateListener(ecoBatteryManager)
    private val powerModeListener = PowerModeListener(ecoBatteryManager)
    private val connectivityStateListener = ConnectivityStateListener(pluginScope, context, permissionHandler)

    // ------------------- PluginActivityComponent implementation ------------------
    override val requestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener
        get() = permissionHandler

    override val batteryLevelStreamListener: DisposableStreamListener
        get() = batteryLevelListener

    override val batteryStateStreamListener: DisposableStreamListener
        get() = batteryStateListener

    override val powerModeStreamListener: DisposableStreamListener
        get() = powerModeListener

    override val connectivityStreamListener: DisposableStreamListener
        get() = connectivityStateListener

    override fun updateActivity(binding: ActivityPluginBinding?) {
        permissionHandler.activity = binding?.activity
    }

    // ------------------- EcoModeApi implementation ------------------
    override fun getPlatformInfo(): String {
        val release: String = Build.VERSION.RELEASE
        val device: String = Build.DEVICE
        val hardware: String = Build.HARDWARE
        val product: String = Build.PRODUCT
        val type: String = Build.TYPE
        return "Android - $release - $device - $hardware - $product - $type"
    }

    override fun getBatteryLevel(): Double = ecoBatteryManager.getBatteryLevel()

    override fun getBatteryState(): BatteryState = ecoBatteryManager.getBatteryState()

    override fun isBatteryInLowPowerMode(): Boolean = ecoBatteryManager.isLowPowerMode()

    override fun getThermalState(): ThermalState {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            return powerManager.currentThermalStatus.toThermalState()
        }
        return ThermalState.UNKNOWN
    }

    override fun getProcessorCount(): Long {
        return Runtime.getRuntime().availableProcessors().toLong()
    }

    override fun getTotalMemory(): Long {
        val memoryInfo = ActivityManager.MemoryInfo()
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.totalMem
    }

    override fun getFreeMemory(): Long {
        val memoryInfo = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memoryInfo)
        return memoryInfo.availMem
    }

    override fun getTotalStorage(): Long {
        try {
            val statFs = StatFs(Environment.getDataDirectory().absolutePath)
            val blockSizeLong = statFs.blockSizeLong
            val totalBlocksLong = statFs.blockCountLong
            return blockSizeLong * totalBlocksLong
        } catch (e: IllegalArgumentException) {
            throw FlutterError(
                code = "STORAGE_ERROR",
                message = "Error while retrieving total storage: ${e.message}",
                details = null
            )
        }
    }

    override fun getFreeStorage(): Long {
        try {
            val statFs = StatFs(Environment.getDataDirectory().absolutePath)
            val blockSizeLong = statFs.blockSizeLong
            val availableBlocksLong = statFs.availableBlocksLong
            return blockSizeLong * availableBlocksLong
        } catch (e: IllegalArgumentException) {
            throw FlutterError(
                code = "STORAGE_ERROR",
                message = "Error while retrieving free storage: ${e.message}",
                details = null
            )
        }
    }

    override fun getEcoScore(): Double {
        val nbrParams = 3.0
        var score = nbrParams

        if (getTotalMemory() <= TOTAL_MEMORY_MINIMUM_THRESHOLD) score--
        if (getProcessorCount() <= PROCESSOR_COUNT_MINIMUM_THRESHOLD) score--
        if (getTotalStorage() <= TOTAL_STORAGE_MINIMUM_THRESHOLD) score--

        return score / nbrParams
    }

    override fun getConnectivity(callback: (Result<Connectivity>) -> Unit) {
        pluginScope.launch {
            val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
            val networkCapabilities = withContext(Dispatchers.IO) {
                connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)
            }

            // Reading the precise cellular network type requires the phone-state
            // permission, but Wifi/Ethernet/no-network don't need it at all: only
            // gate on the permission when the active network is actually cellular.
            val isCellular = networkCapabilities?.hasTransport(TRANSPORT_CELLULAR) == true
            if (isCellular && !permissionHandler.hasReadPhoneStatePermission()) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "PERMISSION_DENIED",
                            message = "READ_BASIC_PHONE_STATE permission denied. Cannot access cellular network type.",
                            details = null
                        )
                    )
                )
                return@launch
            }

            val result = withContext(Dispatchers.IO) {
                val telephonyManager = context.getSystemService(TelephonyManager::class.java)

                try {
                    val connectivity = Connectivity(
                        type = getNetworkType(
                            networkCapabilities = networkCapabilities,
                            telephonyManager = telephonyManager
                        ),
                        wifiSignalStrength = networkCapabilities?.getWifiSignalStrength(context)
                    )

                    Result.success(connectivity)

                } catch (e: SecurityException) {
                    Result.failure(
                        FlutterError(
                            code = "PERMISSION_ERROR",
                            message = "Error while accessing network type: ${e.message}",
                            details = null
                        )
                    )
                }
            }

            callback(result)
        }
    }

    override fun requestNetworkStatePermission(callback: (Result<Boolean>) -> Unit) {
        pluginScope.launch {
            try {
                val granted = permissionHandler.requestNetworkStatePermission()
                callback(Result.success(granted))

            } catch (e: IllegalStateException) {
                callback(Result.failure(FlutterError(
                    code = "ACTIVITY_NOT_ATTACHED",
                    message = e.message ?: "Plugin not attached to an Activity",
                    details = e.cause
                )))
            }
        }
    }

    override fun requestPhoneStatePermission(callback: (Result<Boolean>) -> Unit) {
        pluginScope.launch {
            try {
                val granted = permissionHandler.requestReadPhoneStatePermission()
                callback(Result.success(granted))

            } catch (e: IllegalStateException) {
                callback(Result.failure(FlutterError(
                    code = "ACTIVITY_NOT_ATTACHED",
                    message = e.message ?: "Plugin not attached to an Activity",
                    details = e.cause
                )))
            }
        }
    }
}
