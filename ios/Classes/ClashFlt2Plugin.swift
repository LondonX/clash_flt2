import Flutter
import UIKit

public class ClashFlt2Plugin: NSObject, FlutterPlugin {
    private let vpnManager = VPNManager.shared
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clash_flt2", binaryMessenger: registrar.messenger())
        let instance = ClashFlt2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argsMap = call.arguments as? [String : NSObject]
        switch call.method {
        case "isRunning":
            Task.init {
                let controller = await vpnManager.loadController()
                let isRunning = controller?.connectionStatus == .connected
                result(isRunning)
            }
            break
        case "startTun":
            let yamlFile = argsMap!["yamlFile"] as! String
            let clashHome = argsMap!["clashHome"] as! String
            let sharedYamlFile = copyFileToSharedDirectory(sourcePath: yamlFile)!
            let sharedClashHome = copyFileToSharedDirectory(sourcePath: clashHome)!
            Task.init {
                var modifiedArgs = argsMap!
                modifiedArgs["yamlFile"] = sharedYamlFile as NSObject
                modifiedArgs["clashHome"] = sharedClashHome as NSObject
                do {
                    try await vpnManager.installVPNConfiguration()
                    let controller = await vpnManager.loadController()
                    if(controller == nil) {
                        result(false)
                        return
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)//0.1s
                    try await controller?.startVPN(args: modifiedArgs)
                } catch {
                    result(false)
                    return
                }
                result(true)
            }
            break
        case "stopTun":
            vpnManager.controller?.stopVPN()
            result(nil)
            break
        case "update":
            var modifiedArgs = argsMap!
            modifiedArgs["method"] = "update" as NSObject
            let yamlFile = argsMap!["yamlFile"] as? String
            let clashHome = argsMap!["clashHome"] as? String
            if (yamlFile != nil) {
                let sharedYamlFile = copyFileToSharedDirectory(sourcePath: yamlFile!)!
                modifiedArgs["yamlFile"] = sharedYamlFile as NSObject
            }
            if (clashHome != nil) {
                let sharedClashHome = copyFileToSharedDirectory(sourcePath: clashHome!)!
                modifiedArgs["clashHome"] = sharedClashHome as NSObject
            }
            let data = try! JSONSerialization.data(withJSONObject: modifiedArgs)
            Task.init {
                let controller = await vpnManager.loadController()
                let isRunning = controller?.connectionStatus == .connected
                if (isRunning) {
                    _ = await controller?.sendProviderMessage(data)
                }
                result(nil)
            }
            break
        case "getTraffic":
            let dataMap = ["method" : "getTraffic" as NSObject]
            let data = try! JSONSerialization.data(withJSONObject: dataMap)
            Task.init {
                let controller = await vpnManager.loadController()
                let trafficData = await controller?.sendProviderMessage(data)
                let trafficJson = trafficData == nil ? nil : String(data: trafficData!, encoding: .utf8)
                result(trafficJson)
            }
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

func copyFileToSharedDirectory(sourcePath: String) -> String? {
    let fileManager = FileManager.default
    let sourceURL = URL(fileURLWithPath: sourcePath)
    let fileName = sourceURL.lastPathComponent
    if let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier!)") {
        let destinationURL = sharedContainerURL.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    } else {
        print("Shared directory URL not found.")
        return nil
    }
}
