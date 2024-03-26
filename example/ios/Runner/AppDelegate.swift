import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        MethodHandler.register(with: self.registrar(forPlugin: MethodHandler.name)!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
