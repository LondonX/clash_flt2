//
//  Tun2SocksPacketTunnelProvider.swift
//  clash_flt2
//
//  Created by LondonX on 2023/10/9.
//

import Foundation
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    let libClash = ClashBridge()
    var port: Int?
    var socksPort: Int?
    var yamlFile: String?
    var clashHome: String?
    var mode: String?
    var groupName: String?
    var proxyName: String?
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        let port = options!["port"] as! Int
        let socksPort = options!["socksPort"] as! Int
        self.port = port
        self.socksPort = socksPort
        
        NSLog("[PacketTunel]startTunnel port: \(port), socksPort: \(socksPort)")
        updateClash(options!)
        
        if (port != 0) {
            try await self.setTunnelNetworkSettings(initHttpSettings(port))
        }
    }
    
    override func handleAppMessage(_ data: Data) async -> Data? {
        let args = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: NSObject]
        switch(args["method"] as? String) {
        case "update":
            updateClash(args)
            break
        case "getTraffic":
            let traffic = libClash.getTraffic()
            return traffic?.data(using: .utf8)
        default:
            break
        }
        return nil
    }
    
    private func updateClash(_ args: [String: NSObject]) {
        let yamlFile = args["yamlFile"] as? String
        let clashHome = args["clashHome"] as? String
        let mode = args["mode"] as? String
        let groupName = args["groupName"] as? String
        let proxyName = args["proxyName"] as? String
        
        let needUpdateYamlFile = yamlFile != nil && self.yamlFile != yamlFile
        let needUpdateClashHome = clashHome != nil && self.clashHome != clashHome
        
        var ret = false
        if (needUpdateYamlFile) {
            ret = libClash.setConfig(configPath: yamlFile!)
            NSLog("[PacketTunel]updateClash setConfig: \(ret)")
            if (ret) {
                self.yamlFile = yamlFile
            }
        }
        if (needUpdateClashHome) {
            ret = libClash.setHomeDir(homeDirPath: clashHome!)
            NSLog("[PacketTunel]updateClash setHomeDir: \(ret)")
            if (ret) {
                self.clashHome = clashHome
            }
        }
        if (needUpdateYamlFile || needUpdateClashHome) {
            ret = libClash.clashInit(homeDirPath: clashHome!)
            NSLog("[PacketTunel]updateClash clashInit: \(ret)")
            ret = libClash.parseOptions()
            NSLog("[PacketTunel]updateClash parseOptions: \(ret)")
        }
        if (mode != nil && self.mode != mode) {
            libClash.setTunMode(mode: mode!)
            let result = libClash.getTunMode()!
            ret = result == mode
            NSLog("[PacketTunel]updateClash setTunMode: \(ret), result: \(result)")
            if (ret) {
                self.mode = mode
            }
        }
        let actualGroupName = groupName ?? self.groupName
        let actualProxyName = proxyName ?? self.proxyName
        if (actualGroupName != self.groupName || actualProxyName != self.proxyName) {
            ret = libClash.changeProxy(selectorName: actualGroupName!, proxyName: actualProxyName!)
            NSLog("[PacketTunel]updateClash changeProxy: \(ret)")
            if (ret) {
                self.groupName = actualGroupName
                self.proxyName = actualProxyName
            }
        }
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
