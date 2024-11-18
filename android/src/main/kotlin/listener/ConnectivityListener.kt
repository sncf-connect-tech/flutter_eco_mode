package listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.ConnectivityManager.NetworkCallback
import android.net.ConnectivityManager.TYPE_ETHERNET
import android.net.ConnectivityManager.TYPE_MOBILE
import android.net.ConnectivityManager.TYPE_MOBILE_DUN
import android.net.ConnectivityManager.TYPE_MOBILE_HIPRI
import android.net.ConnectivityManager.TYPE_WIFI
import android.net.ConnectivityManager.TYPE_WIMAX
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_ETHERNET
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.telephony.TelephonyManager.NETWORK_TYPE_1xRTT
import android.telephony.TelephonyManager.NETWORK_TYPE_CDMA
import android.telephony.TelephonyManager.NETWORK_TYPE_EDGE
import android.telephony.TelephonyManager.NETWORK_TYPE_EHRPD
import android.telephony.TelephonyManager.NETWORK_TYPE_EVDO_0
import android.telephony.TelephonyManager.NETWORK_TYPE_EVDO_A
import android.telephony.TelephonyManager.NETWORK_TYPE_EVDO_B
import android.telephony.TelephonyManager.NETWORK_TYPE_GPRS
import android.telephony.TelephonyManager.NETWORK_TYPE_GSM
import android.telephony.TelephonyManager.NETWORK_TYPE_HSDPA
import android.telephony.TelephonyManager.NETWORK_TYPE_HSPA
import android.telephony.TelephonyManager.NETWORK_TYPE_HSPAP
import android.telephony.TelephonyManager.NETWORK_TYPE_HSUPA
import android.telephony.TelephonyManager.NETWORK_TYPE_LTE
import android.telephony.TelephonyManager.NETWORK_TYPE_NR
import android.telephony.TelephonyManager.NETWORK_TYPE_TD_SCDMA
import android.telephony.TelephonyManager.NETWORK_TYPE_UMTS
import android.util.Log
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.Connectivity
import sncf.connect.tech.flutter_eco_mode.ConnectivityType
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.ETHERNET
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE2G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE3G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE4G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE5G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.NONE
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.WIFI


class ConnectivityListener(private val context: Context) : EventChannel.StreamHandler {

    private var connectivityStateEventSink: EventChannel.EventSink? = null
    private var connectivityStateReceiver: BroadcastReceiver? = null
    private var networkCallback: NetworkCallback? = null
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    @RequiresApi(Build.VERSION_CODES.M)
    private val connectivityManager: ConnectivityManager = context.getSystemService(
        ConnectivityManager::class.java
    )

    @RequiresApi(Build.VERSION_CODES.M)
    private val telephonyManager: TelephonyManager = context.getSystemService(
        TelephonyManager::class.java
    )

    @RequiresApi(Build.VERSION_CODES.R)
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        connectivityStateEventSink = events
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            networkCallback = object : NetworkCallback() {
                override fun onAvailable(network: Network) {
                    Log.d(TAG, "The default network is now: $network")
                    sendEvent(
                        networkCapabilities = connectivityManager.getNetworkCapabilities(network),
                        telephonyManager = telephonyManager
                    )
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities
                ) {
                    Log.d(TAG, "The default network changed capabilities: $networkCapabilities")
                    sendEvent(
                        networkCapabilities = networkCapabilities,
                        telephonyManager = telephonyManager
                    )
                }

                override fun onLost(network: Network) {
                    Log.d(TAG, "Network lost, the last default network was $network")
                    sendEvent(
                        networkCapabilities = connectivityManager.getNetworkCapabilities(network),
                        telephonyManager = telephonyManager
                    )
                }
            }

            connectivityManager.registerDefaultNetworkCallback(networkCallback as NetworkCallback)

        } else {
            connectivityStateReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent?) {
                    sendEvent(telephonyManager = telephonyManager)
                }
            }
            context.registerReceiver(
                connectivityStateReceiver,
                IntentFilter("android.net.conn.CONNECTIVITY_CHANGE")
            )
        }
        sendEvent(telephonyManager = telephonyManager)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onCancel(p0: Any?) {
        networkCallback?.let {
            connectivityManager.unregisterNetworkCallback(it)
        } ?: run {
            try {
                context.unregisterReceiver(connectivityStateReceiver)
            } catch (e: Exception) {
                Log.e(null, "Error on cancel network")
            }
        }
    }


    @RequiresApi(Build.VERSION_CODES.R)
    private fun sendEvent(
        networkCapabilities: NetworkCapabilities? = null,
        telephonyManager: TelephonyManager,
    ) {
        val runnable = Runnable {
            val networkType = connectivityManager.getNetworkType(
                networkCapabilities = networkCapabilities,
                telephonyManager = telephonyManager,
            )
            connectivityStateEventSink?.success(
                Gson().toJson(
                    Connectivity(
                        type = networkType,
                        wifiSignalStrength = networkCapabilities?.getWifiSignalStrength()?.toLong()
                    )
                )
            )
        }
        // Emit events on main thread
        mainHandler.post(runnable)
    }
}

@RequiresApi(Build.VERSION_CODES.R)
@Suppress("DEPRECATION")
fun ConnectivityManager.getNetworkType(
    networkCapabilities: NetworkCapabilities? = null,
    telephonyManager: TelephonyManager,
): ConnectivityType {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        Log.d(TAG, "NOT LEGACY Network")
        return when {
            networkCapabilities?.hasTransport(TRANSPORT_ETHERNET) == true -> ETHERNET
            networkCapabilities?.hasTransport(TRANSPORT_WIFI) == true -> WIFI
            networkCapabilities?.hasTransport(TRANSPORT_CELLULAR) == true -> telephonyManager.networkType()
            else -> NONE
        }
    } else {
        Log.d(TAG, "LEGACY Network")
        return when (activeNetworkInfo?.type) {
            TYPE_ETHERNET -> ETHERNET
            TYPE_WIFI -> WIFI
            TYPE_WIMAX -> WIFI
            TYPE_MOBILE,
            TYPE_MOBILE_DUN,
            TYPE_MOBILE_HIPRI -> telephonyManager.networkType()

            else -> NONE
        }

    }
}


@RequiresApi(Build.VERSION_CODES.R)
fun TelephonyManager.networkType(): ConnectivityType {
    Log.d(TAG, "The mobile network is now: $dataNetworkType")
    when (dataNetworkType) {
        NETWORK_TYPE_GPRS,
        NETWORK_TYPE_EDGE,
        NETWORK_TYPE_CDMA,
        NETWORK_TYPE_1xRTT,
        NETWORK_TYPE_GSM
        -> return MOBILE2G

        NETWORK_TYPE_UMTS,
        NETWORK_TYPE_EVDO_0,
        NETWORK_TYPE_EVDO_A,
        NETWORK_TYPE_HSDPA,
        NETWORK_TYPE_HSUPA,
        NETWORK_TYPE_HSPA,
        NETWORK_TYPE_EVDO_B,
        NETWORK_TYPE_EHRPD,
        NETWORK_TYPE_HSPAP,
        NETWORK_TYPE_TD_SCDMA
        -> return MOBILE3G

        NETWORK_TYPE_LTE
        -> return MOBILE4G

        NETWORK_TYPE_NR
        -> return MOBILE5G

        else -> return UNKNOWN
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
fun NetworkCapabilities.getWifiSignalStrength(): Int? = let { transportInfo as? WifiInfo }?.rssi
