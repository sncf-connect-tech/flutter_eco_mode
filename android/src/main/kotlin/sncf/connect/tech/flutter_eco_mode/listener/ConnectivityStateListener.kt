package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.net.ConnectivityManager
import android.net.ConnectivityManager.NetworkCallback
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_ETHERNET
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import sncf.connect.tech.flutter_eco_mode.Connectivity
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.ETHERNET
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.NONE
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.WIFI
import sncf.connect.tech.flutter_eco_mode.ConnectivityStreamHandler
import sncf.connect.tech.flutter_eco_mode.MessagesPigeonMethodCodec
import sncf.connect.tech.flutter_eco_mode.PermissionHandler
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink
import sncf.connect.tech.flutter_eco_mode.getWifiSignalStrength
import sncf.connect.tech.flutter_eco_mode.networkType

class ConnectivityStateListener(
    private val pluginScope: CoroutineScope,
    private val context: Context,
    private val permissionHandler: PermissionHandler,
) : ConnectivityStreamHandler(), DisposableStreamListener {
    private val connectivityManager: ConnectivityManager = context.getSystemService(ConnectivityManager::class.java)
    private val telephonyManager: TelephonyManager = context.getSystemService(TelephonyManager::class.java)

    private var networkCallback: NetworkCallback? = null
    private var eventSink: PigeonEventSink<Connectivity>? = null
    private var connectivityStateReceiver: BroadcastReceiver? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Connectivity>) {
        eventSink = sink

        pluginScope.launch {
            if (!permissionHandler.hasNetworkStatePermission()) {
                sink.error("PERMISSION_DENIED", "ACCESS_NETWORK_STATE is required for this stream", null)
                Log.w(TAG, "ACCESS_NETWORK_STATE permission not granted. Connectivity changes will not be monitored.")
                return@launch
            }

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
            val activeCaps = connectivityManager.activeNetwork?.let {
                connectivityManager.getNetworkCapabilities(it)
            }
            sendEvent(activeCaps, telephonyManager)
        }
    }

    override fun onCancel(p0: Any?) {
        pluginScope.coroutineContext.cancelChildren()
        cleanUp()
    }

    override fun register(binaryMessenger: BinaryMessenger) = register(binaryMessenger, this)

    override fun dispose(binaryMessenger: BinaryMessenger) {
        cleanUp()

        EventChannel(binaryMessenger, EcoModeEventChannels.CONNECTIVITY, MessagesPigeonMethodCodec).setStreamHandler(null)
    }

    private fun sendEvent(
        networkCapabilities: NetworkCapabilities? = null,
        telephonyManager: TelephonyManager,
    ) {
        pluginScope.launch {
            val result = withContext(Dispatchers.IO) {
                val wifiSignalStrength = networkCapabilities?.getWifiSignalStrength(context)

                val networkType = when {
                    networkCapabilities?.hasTransport(TRANSPORT_ETHERNET) == true -> ETHERNET
                    networkCapabilities?.hasTransport(TRANSPORT_WIFI) == true -> WIFI
                    networkCapabilities?.hasTransport(TRANSPORT_CELLULAR) == true -> {
                        try {
                            telephonyManager.networkType()
                        } catch (e: SecurityException) {
                            Log.e(TAG, "SecurityException while accessing network type: ${e.message}")
                            UNKNOWN
                        }
                    }
                    else -> NONE
                }

                networkType to wifiSignalStrength
            }

            eventSink?.success(
                Connectivity(
                    type = result.first,
                    wifiSignalStrength = result.second
                )
            )
        }
    }

    private fun cleanUp() {
        networkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error while unregistering the network callback", e)
            }
        }

        connectivityStateReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error while unregistering the connectivity receiver", e)
            }
        }

        networkCallback = null
        connectivityStateReceiver = null
        eventSink = null
    }
}
