package com.LondonX.clash_flt2.service

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import com.LondonX.tun2socks.Tun2Socks
import io.flutter.BuildConfig
import kotlinx.coroutines.*
import kotlin.coroutines.resume

class TunService : VpnService() {
    companion object {
        var isTunRunning = false
            private set

        suspend fun bind(context: Context): TunService {
            return suspendCancellableCoroutine { continuation ->
                context.bindService(
                    Intent(context, TunService::class.java), object : ServiceConnection {
                        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                            continuation.resume((binder as LocalBinder).service)
                        }

                        override fun onServiceDisconnected(name: ComponentName) {
                        }
                    }, Context.BIND_AUTO_CREATE
                )
            }
        }
    }

    private val binder: IBinder = LocalBinder()

    private inner class LocalBinder : Binder() {
        val service: TunService get() = this@TunService
    }

    override fun onCreate() {
        Tun2Socks.initialize(this)
        super.onCreate()
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun stopService(name: Intent?): Boolean {
        Tun2Socks.stopTun2Socks()
        sendBroadcast(Intent("clash_flt2#proxyEnabled").putExtra("systemProxyEnabled", false))
        super.onDestroy()
        // tun status
        isTunRunning = false
        tunning?.cancel()
        vpnFd?.close()
        return true
    }

    private var tunning: Job? = null
    private var vpnFd: ParcelFileDescriptor? = null

    fun startTun(port: Int, socksPort: Int) {
        if (isTunRunning) return
        val setup = setupVpn(port)
        vpnFd = setup.fd
        if (socksPort != 0) {
            tunning = MainScope().launch {
                withContext(Dispatchers.IO) {
                    protect(setup.fd.fd)
                    Tun2Socks.startTun2Socks(
                        if (!BuildConfig.DEBUG) Tun2Socks.LogLevel.WARNING else Tun2Socks.LogLevel.INFO,
                        setup.fd,
                        TUN_MTU,
                        "127.0.0.1",
                        socksPort,
                        TUN_GATEWAY,
                        null,
                        "255.255.255.255",
                        false,
                        emptyList(),
                    )
                }
            }
        }
        isTunRunning = true
    }

    private fun setupVpn(port: Int): VpnSetup {
        val builder = Builder().addAddress(TUN_GATEWAY, TUN_SUBNET_PREFIX).setMtu(TUN_MTU)
            .addRoute(NET_ANY, 0).apply {
                //TODO prevent loops
                addDisallowedApplication(packageName)
            }.allowBypass().setBlocking(true).setSession("Clash").setConfigureIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent().setComponent(ComponentName(packageName, "$packageName.MainActivity")),
                    pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT)
                )
            ).apply {
                if (Build.VERSION.SDK_INT < 29) return@apply
                if (port == 0) return@apply
                setMetered(false)
                setHttpProxy(
                    ProxyInfo.buildDirectProxy(
                        "127.0.0.1",
                        port,
                        HTTP_PROXY_LOCAL_LIST,
                    )
                )
            }
        val fd = builder.establish()
        return VpnSetup(fd!!, port)
    }
}

private const val TAG = "ClashVpnService"

private const val TUN_MTU = 9000
private const val TUN_SUBNET_PREFIX = 30
private const val TUN_GATEWAY = "172.19.0.1"
private const val NET_ANY = "0.0.0.0"


private val HTTP_PROXY_LOCAL_LIST = listOf(
    "localhost",
    "*.local",
    "127.*",
    "10.*",
    "172.16.*",
    "172.17.*",
    "172.18.*",
    "172.19.*",
    "172.2*",
    "172.30.*",
    "172.31.*",
    "192.168.*"
)

private fun pendingIntentFlags(flags: Int, mutable: Boolean = false): Int {
    return if (Build.VERSION.SDK_INT > 30 && mutable) {
        flags or PendingIntent.FLAG_MUTABLE
    } else {
        flags or PendingIntent.FLAG_IMMUTABLE
    }
}

data class VpnSetup(val fd: ParcelFileDescriptor, val port: Int)