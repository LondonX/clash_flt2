package com.LondonX.clash_flt2

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import com.LondonX.clash_flt2.service.TunService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import kotlin.coroutines.resume

private const val ACTION_PREPARE_VPN = 0xF1

class ClashFlt2Plugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private val scope = MainScope()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "clash_flt2")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startTun" -> {
                val mixedPort = call.argument<Int>("mixedPort")!!
                val port = if(mixedPort != 0) {
                    mixedPort
                } else {
                    call.argument<Int>("port")!!
                }
                val socksPort = if(mixedPort != 0) {
                    mixedPort
                } else {
                    call.argument<Int>("socksPort")!!
                }
                clashServiceScope(result) {
                    val prepared = prepareVpn()
                    if (!prepared) {
                        result.success(false)
                        return@clashServiceScope
                    }
                    it.startTun(port, socksPort)
                    result.success(true)
                }
            }
            "stopTun" -> {
                service?.stopService(null)
                result.success(true)
            }
            "isRunning" -> result.success(TunService.isTunRunning)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private var activity: Activity? = null
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.removeActivityResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == ACTION_PREPARE_VPN) {
            if (scope.isActive && vpnPreparing?.isActive == true) {
                vpnPreparing?.resume(resultCode == Activity.RESULT_OK)
            }
            return true
        }
        return false
    }

    private var vpnPreparing: CancellableContinuation<Boolean>? = null
    private suspend fun prepareVpn(): Boolean {
        val activity = activity ?: return false
        val prepareIntent = VpnService.prepare(activity) ?: return true
        activity.startActivityForResult(prepareIntent, ACTION_PREPARE_VPN)
        return suspendCancellableCoroutine {
            vpnPreparing = it
        }
    }

    private var service: TunService? = null
    private fun clashServiceScope(
        result: Result,
        withService: suspend CoroutineScope.(TunService) -> Unit,
    ) {
        val activity = this.activity
        if (activity == null) {
            result.error("Clash.startClash", "activity is null!!!", null)
            return
        }
        scope.launch {
            service = TunService.bind(activity)
            withService.invoke(this, service!!)
        }
    }
}
