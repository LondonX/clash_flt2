//
//  SharedFile.swift
//  clash_flt2
//
//  Created by LondonX on 2024/3/21.
//

import Foundation

public class SharedConfig {
    private var syncData: [String : Any] = [:]
    
    public init() {
        load()
    }
    
    public func saveChangeProxy(selectorName: String, proxyName: String) {
        syncData["changeProxy"] = [
            "selectorName": selectorName,
            "proxyName": proxyName,
        ]
        save()
    }
    
    public func saveClashInit(homeDir: String) {
        syncData["clashInit"] = homeDir
        save()
    }
    
    public func saveSetConfig(configPath: String) {
        syncData["setConfig"] = configPath
        save()
    }
    
    public func saveSetHomeDir(home: String) {
        syncData["setHomeDir"] = home
        save()
    }
    
    public func saveSetTunMode(s: String) {
        syncData["setTunMode"] = s
        save()
    }
    
    public func saveStartLog() {
        syncData["startLog"] = true
        save()
    }
    
    public func saveStopLog() {
        syncData.removeValue(forKey: "startLog")
        save()
    }
    
    public func applyToClash(clashClient: ClashAppClient) async {
        let shouldStartLog = syncData["startLog"] as? Bool
        if(shouldStartLog == true) {
            let _ = await clashClient.startLog()
        }

        let _ = await clashClient.setConfig(configPath: syncData["setConfig"] as! String)
        let _ = await clashClient.setHomeDir(home: syncData["setHomeDir"] as! String)
        let _ = await clashClient.clashInit(homeDir: syncData["clashInit"] as! String)
        let _ = await clashClient.parseOptions()
        
        let changeProxyParams = syncData["changeProxy"] as? [String : Any]
        if(changeProxyParams != nil) {
            let _ = await clashClient.changeProxy(
                selectorName: changeProxyParams!["selectorName"] as! String,
                proxyName: changeProxyParams!["proxyName"] as! String
            )
        }
        let tunMode = syncData["setTunMode"] as? String
        if(tunMode != nil) {
            let _ = await clashClient.setTunMode(s: tunMode!)
        }
    }
    
    private func save() {
        let jsonData = try! JSONSerialization.data(withJSONObject: syncData)
        try! jsonData.write(to: getSharedFile("SharedConfig.json"))
    }
    
    private func load() {
        let jsonData = try? Data(contentsOf: getSharedFile("SharedConfig.json"))
        if (jsonData == nil) {
            return
        }
        let data = try? JSONSerialization.jsonObject(with: jsonData!) as? [String : Any]
        if(data == nil) {
            return
        }
        syncData = data!
    }
}

private let fileManager = FileManager.default

public func getSharedFile(_ fileName: String, create: Bool = true) -> URL {
    var appGroupId = "group.\(Bundle.main.bundleIdentifier!)"
    if let range = appGroupId.range(of: ".PacketTunnel", options: .backwards) {
        appGroupId.removeSubrange(range)
    }
    let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
    let target = sharedContainerURL.appendingPathComponent(fileName)
    if (create && !fileManager.fileExists(atPath: target.path)) {
        fileManager.createFile(atPath: target.path, contents: nil)
    }
    return target
}

public func makeShared(_ source: URL) -> URL {
    let fileName = source.lastPathComponent
    let shared = getSharedFile(fileName, create: false)
    
    if fileManager.fileExists(atPath: shared.path) {
        try! fileManager.removeItem(at: shared)
    }
    try! fileManager.copyItem(at: source, to: shared)
    return shared
}

public func makeSharedPath(_ filePath: String) -> String {
    let source = URL(fileURLWithPath: filePath)
    let url = makeShared(source)
    return url.path
}
