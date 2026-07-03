package sncf.connect.tech.flutter_eco_mode

import android.Manifest
import android.content.ContentValues.TAG
import android.content.Context
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_ETHERNET
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager.THERMAL_STATUS_CRITICAL
import android.os.PowerManager.THERMAL_STATUS_EMERGENCY
import android.os.PowerManager.THERMAL_STATUS_LIGHT
import android.os.PowerManager.THERMAL_STATUS_MODERATE
import android.os.PowerManager.THERMAL_STATUS_NONE
import android.os.PowerManager.THERMAL_STATUS_SEVERE
import android.os.PowerManager.THERMAL_STATUS_SHUTDOWN
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
import androidx.annotation.RequiresPermission
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.ETHERNET
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE2G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE3G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE4G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.MOBILE5G
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.NONE
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.WIFI
import sncf.connect.tech.flutter_eco_mode.ThermalState.CRITICAL
import sncf.connect.tech.flutter_eco_mode.ThermalState.FAIR
import sncf.connect.tech.flutter_eco_mode.ThermalState.SAFE
import sncf.connect.tech.flutter_eco_mode.ThermalState.SERIOUS

@RequiresPermission(anyOf = [Manifest.permission.READ_PHONE_STATE, Manifest.permission.READ_BASIC_PHONE_STATE])
fun getNetworkType(
    networkCapabilities: NetworkCapabilities? = null,
    telephonyManager: TelephonyManager,
): ConnectivityType {
    Log.d(TAG, "NOT LEGACY Network")
    return when {
        networkCapabilities?.hasTransport(TRANSPORT_ETHERNET) == true -> ETHERNET
        networkCapabilities?.hasTransport(TRANSPORT_WIFI) == true -> WIFI
        networkCapabilities?.hasTransport(TRANSPORT_CELLULAR) == true -> telephonyManager.networkType()
        else -> NONE
    }
}

@RequiresPermission(anyOf = [Manifest.permission.READ_PHONE_STATE, Manifest.permission.READ_BASIC_PHONE_STATE])
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

fun NetworkCapabilities.getWifiSignalStrength(context: Context): Long? {
    return let {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            (transportInfo as? WifiInfo)?.rssi?.toLong()
        } else {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val connectionInfo = wifiManager.connectionInfo
            if (connectionInfo != null && connectionInfo.networkId != -1) {
                connectionInfo.rssi.toLong()
            } else {
                null
            }
        }
    }
}

fun Int.toThermalState(): ThermalState = when (this) {
    THERMAL_STATUS_NONE -> SAFE
    THERMAL_STATUS_MODERATE, THERMAL_STATUS_LIGHT -> FAIR
    THERMAL_STATUS_SEVERE -> SERIOUS
    THERMAL_STATUS_CRITICAL, THERMAL_STATUS_EMERGENCY, THERMAL_STATUS_SHUTDOWN -> CRITICAL
    else -> ThermalState.UNKNOWN
}
