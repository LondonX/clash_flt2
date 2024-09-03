package com.LondonX.clash_flt2.service

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import com.LondonX.tun2socks.Tun2Socks
import io.flutter.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlin.system.exitProcess

private fun getActionStartTun(context: Context): String = "${context.packageName}.ACTION_START_TUN"
private fun getActionStopTun(context: Context): String = "${context.packageName}.ACTION_STOP_TUN"
private fun getActionAskIfRunning(context: Context): String =
    "${context.packageName}.ACTION_ASK_RUNNING"

private fun getActionReportIsRunning(context: Context): String =
    "${context.packageName}.ACTION_IS_RUNNING"

private const val EXTRA_PORT = "EXTRA_PORT"
private const val EXTRA_SOCKS_PORT = "EXTRA_SOCKS_PORT"


class TunService : VpnService() {
    companion object {

        fun start(context: Context, port: Int, socksPort: Int) {
            toggle(context, true, port, socksPort)
        }

        fun stop(context: Context) {
            toggle(context, false, null, null)
        }

        private var runningAwaiting: Continuation<Boolean>? = null

        suspend fun isRunning(context: Context): Boolean {
            val runningReceiver = object : BroadcastReceiver() {
                override fun onReceive(p0: Context?, p1: Intent?) {
                    if (p1?.action != getActionReportIsRunning(context)) return
                    runningAwaiting?.resume(true)
                }
            }
            context.registerReceiverCompat(
                runningReceiver, IntentFilter(getActionReportIsRunning(context)),
            )
            context.sendBroadcast(Intent(getActionAskIfRunning(context)))
            val result = withTimeoutOrNull(100) {
                suspendCoroutine { runningAwaiting = it }
            } ?: false
            context.unregisterReceiver(runningReceiver)
            return result
        }

        private fun toggle(context: Context, enabled: Boolean, port: Int?, socksPort: Int?) {
            context.startService(
                Intent(
                    context, TunService::class.java
                ).setAction(if (enabled) getActionStartTun(context) else getActionStopTun(context))
                    .putExtra(EXTRA_PORT, port).putExtra(EXTRA_SOCKS_PORT, socksPort)
            )
        }
    }

    private val runningCheckReceiver = object : BroadcastReceiver() {
        override fun onReceive(p0: Context?, p1: Intent?) {
            if (p1?.action != getActionAskIfRunning(p0 ?: return)) return
            sendBroadcast(Intent(getActionReportIsRunning(this@TunService)))
        }
    }

    override fun onCreate() {
        Tun2Socks.initialize(this)
        super.onCreate()
        registerReceiverCompat(runningCheckReceiver, IntentFilter(getActionAskIfRunning(this)))
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(runningCheckReceiver)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == getActionStopTun(this)) {
            stopTun()
            return START_NOT_STICKY
        }
        val port: Int = intent?.getIntExtra(EXTRA_PORT, 0) ?: 0
        val socksPort: Int = intent?.getIntExtra(EXTRA_SOCKS_PORT, 0) ?: 0
        startTun(port, socksPort)
        return START_STICKY
    }

    private var tunning: Job? = null
    private var vpnFd: ParcelFileDescriptor? = null

    private fun startTun(port: Int, socksPort: Int) {
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
    }

    private fun stopTun() {
        Tun2Socks.stopTun2Socks()
        sendBroadcast(Intent("clash_flt2#proxyEnabled").putExtra("systemProxyEnabled", false))
        super.onDestroy()
        // tun status
        tunning?.cancel()
        vpnFd?.close()
        stopSelf()
        exitProcess(0)
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

@SuppressLint("UnspecifiedRegisterReceiverFlag")
private fun Context.registerReceiverCompat(receiver: BroadcastReceiver, filter: IntentFilter) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
    } else {
        registerReceiver(receiver, filter)
    }
}