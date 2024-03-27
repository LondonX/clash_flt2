//
//  ClashClient.swift
//  clash_flt2
//
//  Created by LondonX on 2024/3/14.
//

import Foundation

public protocol ClashClientProtocol {
    func setDelayUpdateListener(_ f: @escaping (_ name: String,_ delay: Int) -> Void)
    func setLogListener(_ f: @escaping (_ message: String?) -> Void)
    
    func asyncTestDelay(proxyName: String, url: String, timeout: Int) async
//    func changeConfigField(s: String) async -> Int
    func changeProxy(selectorName: String, proxyName: String) async -> Int
    func clashInit(homeDir: String) async -> Int
//    func clearExtOptions() async
    func closeAllConnections() async
    func closeConnection(connectionId: String) async -> Bool
    func getAllConnections() async -> String
    func getConfig() async -> String
    func getConfigs() async -> String
    func getProviders() async -> String
    func getProxies() async -> String
    func getTraffic() async -> String
    func getTunMode() async -> String
    func isConfigValid(configPath: String) async -> Int
    func parseOptions() async -> Bool
    func setConfig(configPath: String) async -> Int
    func setHomeDir(home: String) async -> Int
    func setTunMode(s: String) async
    func startLog() async
    func stopLog() async
}
