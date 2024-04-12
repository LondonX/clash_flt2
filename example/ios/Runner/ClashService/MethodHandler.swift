//
//  MethodHandler.swift
//  ClashClient
//
//  Created by LondonX on 2024/3/25.
//
import Flutter
import ClashClient

public class MethodHandler: NSObject, FlutterPlugin {
    public static let name = "\(String(describing: Bundle.main.bundleIdentifier))/method"

    private let channel: FlutterMethodChannel
    private let vpnManager = VPNManager.shared
    
    private let clashAppClient = ClashAppClient.shared
    private let clashPacketTunnelClient: ClashPacketTunnelClient
    private let sharedConfig = SharedConfig()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clash_flt2", binaryMessenger: registrar.messenger())
        let instance = MethodHandler(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(_ channel: FlutterMethodChannel) {
        self.channel = channel
        self.clashAppClient.setDelayUpdateListener({ name, delay in
            DispatchQueue.main.async {
                channel.invokeMethod("onDelayUpdate", arguments: ["name": name, "delay": delay])
            }
        })
        self.clashAppClient.setLogListener({ message in
            DispatchQueue.main.async {
                channel.invokeMethod("onLogReceived", arguments: ["message": message])
            }
        })
        vpnManager.setVPNStatusListener { status in
            switch(status) {
            case .connecting:
                channel.invokeMethod("onVPNStatusChange", arguments: ["status": "connecting"])
                break
            case .connected:
                channel.invokeMethod("onVPNStatusChange", arguments: ["status": "connected"])
                break
            case .disconnecting:
                channel.invokeMethod("onVPNStatusChange", arguments: ["status": "disconnecting"])
                break
            case .disconnected:
                channel.invokeMethod("onVPNStatusChange", arguments: ["status": "disconnected"])
                break
            default:
                break
            }
        }
        clashPacketTunnelClient = ClashPacketTunnelClient(
            channel: channel,
            getController: {
                return await VPNManager.shared.loadController()
            }
        )
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argsMap = call.arguments as? [String : NSObject]
        switch call.method {
        case "asyncTestDelay":
            let proxyName = argsMap?["proxyName"] as! String
            let url = argsMap?["url"] as! String
            let timeout = argsMap?["timeout"] as! Int
            withClash(result) { app, packetTunnel, currentClient in
                return await app.asyncTestDelay(proxyName: proxyName, url: url, timeout: timeout)
            }
        case "changeProxy":
            let selectorName = argsMap?["selectorName"] as! String
            let proxyName = argsMap?["proxyName"] as! String
            sharedConfig.saveChangeProxy(selectorName: selectorName, proxyName: proxyName)
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.changeProxy(selectorName: selectorName, proxyName: proxyName)
                return await app.changeProxy(selectorName: selectorName, proxyName: proxyName)
            }
        case "clashInit":
            let homeDir = argsMap?["homeDir"] as! String
            let sharedPath = makeSharedPath(homeDir)
            sharedConfig.saveClashInit(homeDir: sharedPath)
            withClash(result) { app, packetTunnel, currentClient in
                return await app.clashInit(homeDir: homeDir)
            }
        case "closeAllConnections":
            withClash(result) { app, packetTunnel, currentClient in
                return await packetTunnel?.closeAllConnections()
            }
        case "closeConnection":
            let connectionId = argsMap?["connectionId"] as! String
            withClash(result) { app, packetTunnel, currentClient in
                return await packetTunnel?.closeConnection(connectionId: connectionId)
            }
        case "getAllConnections":
            withClash(result) { app, packetTunnel, currentClient in
                return await packetTunnel?.getAllConnections()
            }
        case "getConfig":
            withClash(result) { app, packetTunnel, currentClient in
                return await currentClient.getConfig()
            }
        case "getConfigs":
            withClash(result) { app, packetTunnel, currentClient in
                return await currentClient.getConfigs()
            }
        case "getProviders":
            withClash(result) { app, packetTunnel, currentClient in
                return await currentClient.getProviders()
            }
        case "getProxies":
            withClash(result) { app, packetTunnel, currentClient in
                return await currentClient.getProxies()
            }
        case "getTraffic":
            withClash(result) { app, packetTunnel, currentClient in
                return await packetTunnel?.getTraffic()
            }
        case "getTunMode":
            withClash(result) { app, packetTunnel, currentClient in
                return await currentClient.getTunMode()
            }
        case "isConfigValid":
            let configPath = argsMap?["configPath"] as! String
            withClash(result) { app, packetTunnel, currentClient in
                return await app.isConfigValid(configPath: configPath)
            }
        case "parseOptions":
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.parseOptions()
                return await app.parseOptions()
            }
        case "setConfig":
            let configPath = argsMap?["configPath"] as! String
            let sharedPath = makeSharedPath(configPath)
            let shadowPath = argsMap?["shadowConfigPath"] as! String
            sharedConfig.saveSetConfig(configPath: sharedPath)
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.setConfig(configPath: sharedPath)
                return await app.setConfig(configPath: shadowPath)
            }
        case "setHomeDir":
            let home = argsMap?["home"] as! String
            let sharedPath = makeSharedPath(home)
            sharedConfig.saveSetHomeDir(home: sharedPath)
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.setHomeDir(home: sharedPath)
                return await app.setHomeDir(home: home)
            }
        case "setTunMode":
            let s = argsMap?["s"] as! String
            sharedConfig.saveSetTunMode(s: s)
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.setTunMode(s: s)
                return await app.setTunMode(s: s)
            }
        case "startLog":
            sharedConfig.saveStartLog()
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.startLog()
                return await app.startLog()
            }
        case "stopLog":
            sharedConfig.saveStopLog()
            withClash(result) { app, packetTunnel, currentClient in
                let _ = await packetTunnel?.stopLog()
                return await app.stopLog()
            }
        case "isRunning":
            Task.init {
                let controller = await vpnManager.loadController()
                let isRunning = controller?.connectionStatus == .connected
                result(isRunning)
            }
            break
        case "startSystemProxy":
            Task.init {
                do {
                    try await vpnManager.installVPNConfiguration()
                    try await Task.sleep(nanoseconds: 100_000_000)//0.1s
                    let controller = await vpnManager.loadController()
                    if(controller == nil) {
                        result(false)
                        return
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)//0.1s
                    try await controller?.startVPN(args: argsMap!)
                } catch {
                    result(false)
                    return
                }
                result(true)
            }
            break
        case "stopSystemProxy":
            vpnManager.controller?.stopVPN()
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func withClash(
        _ result: @escaping FlutterResult,
        _ f: @escaping (
            _ app: ClashAppClient,
            _ packetTunnel: ClashPacketTunnelClient?,
            _ currentClient: ClashClientProtocol
        ) async -> Any?
    ) {
        Task.init {
            let packetTunnelClient = await clashPacketTunnelClient.isAlive()
                ? clashPacketTunnelClient
                : nil;
            let currentClient : ClashClientProtocol = packetTunnelClient ?? self.clashAppClient
            let ret = await f(self.clashAppClient, packetTunnelClient, currentClient)
            if (ret == nil || ret is Void) {
                result(nil)
            } else {
                result(ret)
            }
        }
    }
}
