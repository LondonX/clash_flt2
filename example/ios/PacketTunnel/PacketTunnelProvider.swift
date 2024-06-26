//
//  Tun2SocksPacketTunnelProvider.swift
//  clash_flt2
//
//  Created by LondonX on 2023/10/9.
//

import Foundation
import NetworkExtension
import Tun2SocksKit
import ClashClient

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let clashAppClient = ClashAppClient.shared
    private let sharedConfig = SharedConfig()
    private var isAlive = false
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        // clashInit
        await sharedConfig.applyToClash(clashClient: clashAppClient)
        let configsJson = await clashAppClient.getConfigs()
        let configs = try JSONSerialization.jsonObject(with: configsJson.data(using: .utf8)!, options: []) as! [String: Any]
        let mixedPort = configs["mixed-port"] as? Int ?? 0
        if (mixedPort != 0) {
            NSLog("[PacketTunnel]mixedPort: \(mixedPort), overriding port and socksPort")
        }
        let port = mixedPort != 0 ? mixedPort : configs["port"] as? Int ?? 0
        let socksPort = mixedPort != 0 ? mixedPort : configs["socks-port"] as? Int ?? 0
        NSLog("[PacketTunnel]startTunnel port: \(port), socksPort: \(socksPort)")

        try await self.setTunnelNetworkSettings(initHttpSettings(port))
        if (socksPort != 0) {
            // start TUN
            Socks5Tunnel.run(withConfig: .string(content: createTunnelConfig(socksPort: socksPort))) { code in
                NSLog("[PacketTunnel]Socks5Tunnel ret: \(code)")
            }
        }
        isAlive = true
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        isAlive = false
        Socks5Tunnel.quit()
    }
    
    override func handleAppMessage(_ data: Data) async -> Data? {
        let params = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let method = params["method"] as! String
        let args = params["args"] as? [String : Any]
        switch(method) {
        case "asyncTestDelay":
            let proxyName = args!["proxyName"] as! String
            let url = args!["url"] as! String
            let timeout = args!["timeout"] as! Int
            return wrapAppMessageResult(await clashAppClient.asyncTestDelay(proxyName: proxyName, url: url, timeout: timeout))
        case "changeProxy":
            let selectorName = args!["selectorName"] as! String
            let proxyName = args!["proxyName"] as! String
            return wrapAppMessageResult(await clashAppClient.changeProxy(selectorName: selectorName, proxyName: proxyName))
        case "clashInit":
            let homeDir = args!["homeDir"] as! String
            return wrapAppMessageResult(await clashAppClient.clashInit(homeDir: homeDir))
        case "closeAllConnections":
            return wrapAppMessageResult(await clashAppClient.closeAllConnections())
        case "closeConnection":
            let connectionId = args!["connectionId"] as! String
            return wrapAppMessageResult(await clashAppClient.closeConnection(connectionId: connectionId))
        case "getAllConnections":
            return wrapAppMessageResult(await clashAppClient.getAllConnections())
        case "getConfig":
            return wrapAppMessageResult(await clashAppClient.getConfig())
        case "getConfigs":
            return wrapAppMessageResult(await clashAppClient.getConfigs())
        case "getProviders":
            return wrapAppMessageResult(await clashAppClient.getProviders())
        case "getProxies":
            return wrapAppMessageResult(await clashAppClient.getProxies())
        case "getTraffic":
            return wrapAppMessageResult(await clashAppClient.getTraffic())
        case "getTunMode":
            return wrapAppMessageResult(await clashAppClient.getTunMode())
        case "isConfigValid":
            let configPath = args!["configPath"] as! String
            return wrapAppMessageResult(await clashAppClient.isConfigValid(configPath: configPath))
        case "parseOptions":
            return wrapAppMessageResult(await clashAppClient.parseOptions())
        case "setConfig":
            let configPath = args!["configPath"] as! String
            return wrapAppMessageResult(await clashAppClient.setConfig(configPath: configPath))
        case "setHomeDir":
            let home = args!["home"] as! String
            return wrapAppMessageResult(await clashAppClient.setHomeDir(home: home))
        case "setTunMode":
            let s = args!["s"] as! String
            return wrapAppMessageResult(await clashAppClient.setTunMode(s: s))
        case "startLog":
            return wrapAppMessageResult(await clashAppClient.startLog())
        case "stopLog":
            return wrapAppMessageResult(await clashAppClient.stopLog())
        case "isAlive":
            return wrapAppMessageResult(isAlive)
        default:
            break
        }
        return nil
    }
}

private func initHttpSettings(_ port: Int) -> NEPacketTunnelNetworkSettings {
    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
    settings.mtu = 9000
    settings.ipv4Settings = {
        let settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        settings.includedRoutes = [NEIPv4Route.default()]
        return settings
    }()
    settings.ipv6Settings = {
        let settings = NEIPv6Settings(addresses: ["fd6e:a81b:704f:1211::1"], networkPrefixLengths: [64])
        settings.includedRoutes = [NEIPv6Route.default()]
        return settings
    }()
    settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1"])
    settings.proxySettings = {
        let settings = NEProxySettings();
        settings.httpServer = NEProxyServer(address: "::1", port: port)
        settings.httpsServer = NEProxyServer(address: "::1", port: port)
        settings.httpEnabled = true
        settings.httpsEnabled = true
        settings.matchDomains = [""]
        return settings
    }()
    return settings
}

private func createTunnelConfig(socksPort: Int) -> String {
    return """
    tunnel:
      mtu: 9000

    socks5:
      port: \(socksPort)
      address: ::1
      udp: 'udp'

    misc:
      task-stack-size: 2048
      connect-timeout: 5000
      read-write-timeout: 60000
      log-file: stderr
      log-level: info
      limit-nofile: 65535
    """
}

private func wrapAppMessageResult(_ ret: Any?) -> Data? {
    if (ret == nil || ret is Void) {
        return nil
    }
    if (ret is Int) {
        return withUnsafeBytes(of: ret as! Int) { Data($0) }
    }
    if (ret is Bool) {
        return withUnsafeBytes(of: (ret as! Bool) ? 1 : 0) { Data($0) }
    }
    if (ret is String) {
        return (ret as! String).data(using: .utf8)
    }
    return nil
}
