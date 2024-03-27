//
//  ClashClient.swift
//  Runner
//
//  Created by LondonX on 2024/3/14.
//

import Foundation
import Libclash

private class NativeClient : NSObject, FclashClientProtocol {
    
    func delayUpdate(_ name: String?, delay: Int64) {
        guard name != nil else {
            return
        }
        ClashAppClient.shared.delayUpdateListener?(name!, Int(delay))
    }
    
    func log(_ message: String?) {
        guard message != nil else {
            return
        }
        ClashAppClient.shared.logListener?(message!)
    }
}

public class ClashAppClient: ClashClientProtocol {
    public static let shared = ClashAppClient()
    
    private let client = NativeClient()
    var delayUpdateListener: ((_ name: String,_ delay: Int) -> Void)?
    var logListener: ((_ message: String?) -> Void)?
    
    private init() {}
    
    public func setDelayUpdateListener(_ f: @escaping (_ name: String,_ delay: Int) -> Void) {
        delayUpdateListener = f
    }
    
    public func setLogListener(_ f: @escaping (_ message: String?) -> Void) {
        logListener = f
    }
    
    public func asyncTestDelay(proxyName: String, url: String, timeout: Int) async {
        FclashAsyncTestDelay(proxyName, url, Int64(timeout))
    }
    
    public func changeProxy(selectorName: String, proxyName: String) async -> Int {
        return Int(FclashChangeProxy(selectorName, proxyName))
    }
    
    public func clashInit(homeDir: String) async -> Int {
        return Int(FclashClashInit(homeDir, client))
    }
    
    public func closeAllConnections() async {
        FclashCloseAllConnections()
    }
    
    public func closeConnection(connectionId: String) async -> Bool {
        return FclashCloseConnection(connectionId)
    }
    
    public func getAllConnections() async -> String {
        return FclashGetAllConnections()
    }
    
    public func getConfig() async -> String {
        return FclashGetConfig()
    }
    
    public func getConfigs() async -> String {
        return FclashGetConfigs()
    }
    
    public func getProviders() async -> String {
        return FclashGetProviders()
    }
    
    public func getProxies() async -> String {
        return FclashGetProxies()
    }
    
    public func getTraffic() async -> String {
        return FclashGetTraffic()
    }
    
    public func getTunMode() async -> String {
        return FclashGetTunMode()
    }
    
    public func isConfigValid(configPath: String) async -> Int {
        return Int(FclashIsConfigValid(configPath))
    }
    
    public func parseOptions() async -> Bool {
        return FclashParseOptions()
    }
    
    public func setConfig(configPath: String) async -> Int {
        return Int(FclashSetConfig(configPath))
    }
    
    public func setHomeDir(home: String) async -> Int {
        return Int(FclashSetHomeDir(home))
    }
    
    public func setTunMode(s: String) async {
        FclashSetTunMode(s)
    }
    
    public func startLog() async {
        FclashStartLog()
    }
    
    public func stopLog() async {
        FclashStopLog()
    }
    
}
