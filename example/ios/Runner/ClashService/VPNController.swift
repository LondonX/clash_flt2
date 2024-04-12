//
//  VPNController.swift
//  clash_flt
//
//  Created by LondonX on 2022/9/13.
//

import Foundation
import Combine
import NetworkExtension

public final class VPNController: ObservableObject {
    
    private var cancellables: Set<AnyCancellable> = []
    private let providerManager: NETunnelProviderManager
    
    public var connectedDate: Date? {
        self.providerManager.connection.connectedDate
    }
    
    @Published public var connectionStatus: NEVPNStatus
    
    public init(providerManager: NETunnelProviderManager) {
        self.providerManager = providerManager
        self.connectionStatus = providerManager.connection.status
        NotificationCenter.default
            .publisher(for: Notification.Name.NEVPNStatusDidChange, object: self.providerManager.connection)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.handleVPNStatusDidChangeNotification($0) }
            .store(in: &self.cancellables)
    }
    
    private func handleVPNStatusDidChangeNotification(_ notification: Notification) {
        let connection = notification.object as? NEVPNConnection
        if (connection == nil) {
            return
        }
        self.connectionStatus = connection!.status
    }
    
    public func isEqually(manager: NETunnelProviderManager) -> Bool {
        self.providerManager === manager
    }
    
    public func startVPN(args: [String : NSObject]? = nil) async throws {
        switch self.providerManager.connection.status {
        case .disconnecting, .disconnected:
            break
        case .connecting, .connected, .reasserting, .invalid:
            return
        @unknown default:
            break
        }
        if !self.providerManager.isEnabled {
            self.providerManager.isEnabled = true
            try await self.providerManager.saveToPreferences()
        }
        do {
            try self.providerManager.connection.startVPNTunnel(options: args)
        } catch {
            print("error: \(error)")
        }
    }
    
    public func stopVPN() {
        switch self.providerManager.connection.status {
        case .disconnecting, .disconnected, .invalid:
            return
        case .connecting, .connected, .reasserting:
            break
        @unknown default:
            break
        }
        self.providerManager.connection.stopVPNTunnel()
    }
    
    public func sendProviderMessage(_ data: Data) async -> Data? {
        guard self.connectionStatus != .invalid || self.connectionStatus != .disconnected else {
            return nil
        }
        return try? await withCheckedThrowingContinuation { continuation in
            let session = self.providerManager.connection as! NETunnelProviderSession
            do {
                try session.sendProviderMessage(data) {
                    continuation.resume(with: .success($0))
                }
            } catch {
                continuation.resume(with: .failure(error))
            }
        }
    }
}
