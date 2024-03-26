//
//  ClashClient.swift
//  Runner
//
//  Created by LondonX on 2024/3/21.
//

import Flutter
import ClashClient

public class ClashPacketTunnelClient: ClashClientProtocol {
    private let channel: FlutterMethodChannel
    private let getController: () async -> VPNController?
    var delayUpdateListener: ((_ name: String,_ delay: Int) -> Void)?
    var logListener: ((_ message: String?) -> Void)?
    
    init(channel: FlutterMethodChannel, getController: @escaping () async -> VPNController?) {
        self.channel = channel
        self.getController = getController
        
        self.setDelayUpdateListener({ name, delay in
            DispatchQueue.main.async {
                channel.invokeMethod("onDelayUpdate", arguments: ["name": name, "delay": delay])
            }
        })
        self.setLogListener({ message in
            DispatchQueue.main.async {
                channel.invokeMethod("onLogReceived", arguments: ["message": message])
            }
        })
    }
    
    public func isAlive() async -> Bool {
        return await self.getController()?.connectionStatus == .connected
    }
    
    public func setDelayUpdateListener(_ f: @escaping (_ name: String,_ delay: Int) -> Void) {
        delayUpdateListener = f
    }
    
    public func setLogListener(_ f: @escaping (_ message: String?) -> Void) {
        logListener = f
    }
    
    public func asyncTestDelay(proxyName: String, url: String, timeout: Int) async {
        let data = await invokeControllerIntMethod("asyncTestDelay", [
            "proxyName": proxyName,
            "url": url,
            "timeout": timeout,
        ])
        delayUpdateListener?(proxyName, data)
    }
    
    public func changeProxy(selectorName: String, proxyName: String) async -> Int {
        return await invokeControllerIntMethod("changeProxy", ["selectorName": selectorName, "proxyName": proxyName])
    }

    public func clashInit(homeDir: String) async -> Int {
        return await invokeControllerIntMethod("clashInit", ["homeDir": homeDir])
    }

    public func closeAllConnections() async{
        let _ = await invokeControllerMethod("closeAllConnections", nil)
    }

    public func closeConnection(connectionId: String) async -> Bool {
        return await invokeControllerBoolMethod("closeConnection", ["connectionId": connectionId])
    }

    public func getAllConnections() async -> String {
        return await invokeControllerStringMethod("getAllConnections", nil)
    }

    public func getConfig() async -> String {
        return await invokeControllerStringMethod("getConfig", nil)
    }

    public func getConfigs() async -> String {
        return await invokeControllerStringMethod("getConfigs", nil)
    }

    public func getProviders() async -> String {
        return await invokeControllerStringMethod("getProviders", nil)
    }

    public func getProxies() async -> String {
        return await invokeControllerStringMethod("getProxies", nil)
    }

    public func getTraffic() async -> String {
        return await invokeControllerStringMethod("getTraffic", nil)
    }

    public func getTunMode() async -> String {
        return await invokeControllerStringMethod("getTunMode", nil)
    }

    public func isConfigValid(configPath: String) async -> Int {
        return await invokeControllerIntMethod("isConfigValid", ["configPath": configPath])
    }

    public func parseOptions() async -> Bool {
        return await invokeControllerBoolMethod("parseOptions", nil)
    }

    public func setConfig(configPath: String) async -> Int {
        return await invokeControllerIntMethod("setConfig", ["configPath": configPath])
    }

    public func setHomeDir(home: String) async -> Int {
        return await invokeControllerIntMethod("setHomeDir", ["home": home])
    }

    public func setTunMode(s: String) async {
        let _ = await invokeControllerMethod("setTunMode", ["s": s])
    }

    public func startLog() async{
        let _ = await invokeControllerMethod("startLog", nil)
    }

    public func stopLog() async{
        let _ = await invokeControllerMethod("stopLog", nil)
    }
    
    private func invokeControllerMethod(_ method: String, _ args: [String:Any?]?) async -> Data? {
        let controller = await self.getController()!
        return await controller.sendProviderMessage(
            try! JSONSerialization.data(withJSONObject: [
                "method" : method,
                "args": args ?? [:]
            ])
        )
    }
    
    private func invokeControllerIntMethod(_ method: String, _ args: [String:Any?]?) async -> Int {
        let data = await invokeControllerMethod(method, args)!
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }
    
    private func invokeControllerBoolMethod(_ method: String, _ args: [String:Any?]?) async -> Bool {
        let data = await invokeControllerMethod(method, args)!
        return data.withUnsafeBytes { $0.load(as: Bool.self) }
    }
    
    private func invokeControllerStringMethod(_ method: String, _ args: [String:Any?]?) async -> String {
        let data = await invokeControllerMethod(method, args)!
        return String(data: data, encoding: .utf8)!
    }
}
