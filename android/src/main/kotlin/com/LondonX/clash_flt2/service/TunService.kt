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
import com.LondonX.clash_flt2.hev.TProxyService
import io.flutter.BuildConfig
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
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

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun stopService(name: Intent?): Boolean {
        vpnFd?.close()
        TProxyService.TProxyStopService()
        super.onDestroy()
        // tun status
        isTunRunning = false
        return true
    }

    private var vpnFd: ParcelFileDescriptor? = null

    fun startTun(port: Int, socksPort: Int) {
        if (isTunRunning) return
        vpnFd = setupVpn(port)
        if (socksPort != 0) {
            TProxyService.TProxyStartService(createTunConfigFile(socksPort), vpnFd!!.fd)
        }
        isTunRunning = true
    }

    private fun createTunConfigFile(socksPort: Int): String {
        val logLevel = if (!BuildConfig.DEBUG) "warning" else "debug"
        val file = File(filesDir.absolutePath + "/tun/tun_config.yml")
        val content = """
tunnel:
  name: tun${System.currentTimeMillis()}
  mtu: $TUN_MTU
  ipv4: $TUN_GATEWAY
  ipv6: 'fc00::1'

socks5:
  port: $socksPort
  address: 127.0.0.1
  udp: 'udp'

misc:
  task-stack-size: 2048
  connect-timeout: 5000
  read-write-timeout: 60000
  log-file: stdout
  log-level: $logLevel
  limit-nofile: 65535
""".lines().filter { it.isNotBlank() }.joinToString("\n")
        file.parentFile?.mkdirs()
        file.createNewFile()
        file.writeText(content)
        return file.absolutePath
    }

    private fun setupVpn(port: Int): ParcelFileDescriptor {
        val builder = Builder()
            .setBlocking(false)
            .setMtu(TUN_MTU)
            .addAddress(TUN_GATEWAY, TUN_SUBNET_PREFIX)
            .addRoute(NET_ANY, 0)
            .addAddress("fc00::1", 128)
            .addRoute("::", 0)
            .addDisallowedApplication(packageName)
            .setSession("Clash-${System.currentTimeMillis().toString(36)}")
            .setConfigureIntent(
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
        return builder.establish()!!
    }
}

private const val TAG = "ClashVpnService"

private const val TUN_MTU = 8500
private const val TUN_SUBNET_PREFIX = 32
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
