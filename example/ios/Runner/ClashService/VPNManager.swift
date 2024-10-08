import Combine
import NetworkExtension

public final class VPNManager: ObservableObject {
    
    private var cancellables: Set<AnyCancellable> = []
    public var controller: VPNController?
    private var statusChangeListener: ((_ status: NEVPNStatus) -> Void)?
    
    public static let shared = VPNManager()
    
    private let providerBundleIdentifier: String = {
        return "\(Bundle.main.bundleIdentifier!).PacketTunnel"
    }()
    
    private init() {
        NotificationCenter.default
            .publisher(for: .NEVPNConfigurationChange, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.handleVPNConfigurationChangedNotification($0) }
            .store(in: &self.cancellables)
        NotificationCenter.default
            .publisher(for: .NEVPNStatusDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.handleVPNStateChangeNotification($0) }
            .store(in: &self.cancellables)
    }
    
    private func handleVPNConfigurationChangedNotification(_ notification: Notification) {
        Task(priority: .high) {
            try await self.loadController()
        }
    }
    
    public func setVPNStatusListener(l: @escaping (_ status: NEVPNStatus) -> Void) {
        self.statusChangeListener = l
    }
    
    private func handleVPNStateChangeNotification(_ notification: Notification) {
        let connection = notification.object as? NEVPNConnection
        if (connection == nil) {
            return
        }
        if (connection!.status == .disconnected) {
            self.controller = nil
        }
        statusChangeListener?(connection!.status)
    }
    
    func loadController() async -> VPNController? {
        let manager = await self.loadCurrentTunnelProviderManager()
        if (manager == nil) {
            self.controller = nil
        } else {
            if self.controller?.isEqually(manager: manager!) ?? false {
                // Nothing
            } else {
                self.controller = VPNController(providerManager: manager!)
            }
        }
        return self.controller
    }
    
    private func loadCurrentTunnelProviderManager() async -> NETunnelProviderManager? {
        let managers = try? await NETunnelProviderManager.loadAllFromPreferences()
        if (managers == nil) {
            return nil
        }
        let first = managers!.first { manager in
            guard let configuration = manager.protocolConfiguration as? NETunnelProviderProtocol else {
                return false
            }
            return configuration.providerBundleIdentifier == self.providerBundleIdentifier
        }
        do {
            guard let first = first else {
                return nil
            }
            try await first.loadFromPreferences()
            return first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    public func installVPNConfiguration() async throws {
        let manager = (try? await loadCurrentTunnelProviderManager()) ?? NETunnelProviderManager()
        let config = NETunnelProviderProtocol()
        config.providerBundleIdentifier = self.providerBundleIdentifier
        config.serverAddress = "localhost"
        config.disconnectOnSleep = false
        config.providerConfiguration = [:]
//        config.excludeLocalNetworks = true
//        config.includeAllNetworks = true
        manager.protocolConfiguration = config
        manager.isEnabled = true
        manager.isOnDemandEnabled = true
        try await manager.saveToPreferences()
    }
}
