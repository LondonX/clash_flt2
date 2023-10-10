//
//  ClashBridge.swift
//  PacketTunnel
//
//  Created by LondonX on 2023/10/9.
//

import Foundation

class ClashBridge {
    private let libraryHandle: UnsafeMutableRawPointer
    
    init() {
        libraryHandle = dlopen("libclash-ios.dylib", RTLD_NOW)!
    }
    
    deinit {
        dlclose(libraryHandle)
    }
    
    typealias SetConfigFunction = @convention(c) (UnsafePointer<Int8>) -> Int32
    typealias GetConfigFunction = @convention(c) () -> UnsafePointer<Int8>?
    typealias ChangeProxyFunction = @convention(c) (UnsafePointer<Int8>, UnsafePointer<Int8>) -> Int32
    typealias SetTunMode = @convention(c) (UnsafePointer<Int8>) -> Void
    typealias GetTunMode = @convention(c) () -> UnsafePointer<Int8>?
    typealias SetHomeDir = @convention(c) (UnsafePointer<Int8>) -> Int32
    typealias ClashInit = @convention(c) (UnsafePointer<Int8>) -> Int32
    typealias ParseOptions = @convention(c) () -> Int32
    typealias GetTrafficFunction = @convention(c) () -> UnsafePointer<Int8>?
    
    func clashInit(homeDirPath: String) -> Bool {
        if let sym = dlsym(libraryHandle, "clash_init") {
            let function = unsafeBitCast(sym, to: SetHomeDir.self)
            let result = function(homeDirPath)
            return result == 0
        } else {
            print("Failed to find 'clash_init' function: \(String(cString: dlerror()))")
            return false
        }
    }
    
    func parseOptions() -> Bool {
        if let sym = dlsym(libraryHandle, "parse_options") {
            let function = unsafeBitCast(sym, to: ParseOptions.self)
            let result = function()
            return result == 0
        } else {
            print("Failed to find 'parse_options' function: \(String(cString: dlerror()))")
            return false
        }
    }
    
    func setConfig(configPath: String) -> Bool {
        if let sym = dlsym(libraryHandle, "set_config") {
            let function = unsafeBitCast(sym, to: SetConfigFunction.self)
            let result = function(configPath)
            return result == 0
        } else {
            print("Failed to find 'set_config' function: \(String(cString: dlerror()))")
            return false
        }
    }
    
    func getConfig() -> String? {
        if let sym = dlsym(libraryHandle, "get_config") {
            let function = unsafeBitCast(sym, to: GetConfigFunction.self)
            let configPtr = function()
            
            if configPtr != nil {
                return String(cString: configPtr!)
            } else {
                return nil
            }
        } else {
            print("Failed to find 'get_config' function: \(String(cString: dlerror()))")
            return nil
        }
    }
    
    func setHomeDir(homeDirPath: String) -> Bool {
        if let sym = dlsym(libraryHandle, "set_home_dir") {
            let function = unsafeBitCast(sym, to: SetHomeDir.self)
            let result = function(homeDirPath)
            return result == 0
        } else {
            print("Failed to find 'set_home_dir' function: \(String(cString: dlerror()))")
            return false
        }
    }
    
    func changeProxy(selectorName: String, proxyName: String) -> Bool {
        if let sym = dlsym(libraryHandle, "change_proxy") {
            let function = unsafeBitCast(sym, to: ChangeProxyFunction.self)
            let result = function(selectorName, proxyName)
            return result == 0
        } else {
            print("Failed to find 'change_proxy' function: \(String(cString: dlerror()))")
            return false
        }
    }
    
    func setTunMode(mode: String) {
        if let sym = dlsym(libraryHandle, "set_tun_mode") {
            let function = unsafeBitCast(sym, to: SetTunMode.self)
            function(mode)
        } else {
            print("Failed to find 'set_tun_mode' function: \(String(cString: dlerror()))")
        }
    }
    
    func getTunMode() -> String? {
        if let sym = dlsym(libraryHandle, "get_tun_mode") {
            let function = unsafeBitCast(sym, to: GetTunMode.self)
            let configPtr = function()
            
            if configPtr != nil {
                return String(cString: configPtr!)
            } else {
                return nil
            }
        } else {
            print("Failed to find 'get_tun_mode' function: \(String(cString: dlerror()))")
            return nil
        }
    }
    
    func getTraffic() -> String? {
        if let sym = dlsym(libraryHandle, "get_traffic") {
            let function = unsafeBitCast(sym, to: GetTrafficFunction.self)
            let configPtr = function()
            
            if configPtr != nil {
                return String(cString: configPtr!)
            } else {
                return nil
            }
        } else {
            print("Failed to find 'get_traffic' function: \(String(cString: dlerror()))")
            return nil
        }
    }
}

