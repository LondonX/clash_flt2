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
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        let port = options!["port"] as! Int
        let socksPort = options!["socksPort"] as! Int
        NSLog("[PacketTunnel]startTunnel port: \(port), socksPort: \(socksPort)")
        // clashInit
        clashAppClient.setLogListener { message in
            NSLog("[PacketTunnel]clashLog: \(String(describing: message))")
        }
        await sharedConfig.applyToClash(clashClient: clashAppClient)
        if (port != 0) {
            try await self.setTunnelNetworkSettings(initHttpSettings(port))
            if (socksPort != 0) {
                // start TUN
                let tunConfigFile = createTunnelConfigFile(socksPort: socksPort)
                Socks5Tunnel.run(withConfig: .file(path: tunConfigFile)) { code in
                    NSLog("[PacketTunnel]Socks5Tunnel ret: \(code)")
                }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        Socks5Tunnel.quit()
    }
    
    override func handleAppMessage(_ data: Data) async -> Data? {
        let params = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let method = params["method"] as! String
        let args = params["args"] as? [String : Any]
        switch(method) {
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

private func createTunnelConfigFile(socksPort: Int) -> URL {
    let configContent = createTunnelConfig(socksPort: socksPort)
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentsDirectory.appendingPathComponent("tunnel_config.yaml")
        do {
            try configContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            fatalError("Error writing to file: \(error)")
        }
    } else {
        fatalError("Error finding the documents directory.")
    }
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
