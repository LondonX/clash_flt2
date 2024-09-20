package com.LondonX.clash_flt2.hev

object TProxyService {
    init {
        System.loadLibrary("hev-socks5-tunnel")
        TProxyGetStats()
    }
    external fun TProxyStartService(config_path: String, fd: Int)
    external fun TProxyStopService()
    external fun TProxyGetStats(): LongArray?
}