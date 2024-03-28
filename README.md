# Clash for flutter
A Flutter plugin of Clash, support Windows/Mac/Android/iOS.  

Extract clash core from [FClash](https://github.com/Fclash/Fclash).  
Using [ffigen](https://pub.dev/packages/ffigen) to create bridge tween clash core and dart.  

# Build libs
* Requires Golang >= 1.2
* Requires `mingw-w64` for build Windows dll from mac.
* Requires `FiloSottile/musl-cross/musl-cross` for build Linux so from mac.

```shell
cd fclash
./build_libclash.sh
```
It will print like so
```shell
Building libclash.dylib
Building libclash.dll
Building libclash.so
./dist/libclash.dll: PE32+ executable (DLL) (console) x86-64 (stripped to external PDB), for MS Windows
./dist/libclash.h: c program text, ASCII text
./dist/android/armeabi-v7a/libclash.so: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, Go   BuildID=***, stripped
./dist/android/arm64-v8a/libclash.so: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, Go   BuildID=***, stripped
./dist/libclash.dylib: Mach-O 64-bit dynamically linked shared library x86_64
```
* It will create `libclash.dll`, `libclash.dylib`, `libclash.so`, `Libclash.xcframework` and `libclash.h` in `fclash/dist` directory.

# Run ffigen
* Requires LLVM ([Installing LLVM](https://pub.dev/packages/ffigen#installing-llvm))
```shell
dart run ffigen
```

# Platform works
## Mac OS
1. Add `libclash.dylib` into `Runner/Frameworks` (you can uncheck `Copy items if needed` if you want).
2. Set to `Embed & Sign` of `libclash.dylib` in `TARGETS > Runner > General > Frameworks, Libraries, and Embedded content`.
3. Add `libclash.dylib` into `TARGETS > Runner > Build Phases > Copy Bundle Resources`.
4. Change the status of `libclash.dylib` into `Optional` in `TARGETS > Runner > Build Phases > Link Binary With Libraries`.
5. Add path which `libclash.dylib` can be found at (typically `$(PROJECT_DIR)/../fclash/dist`) into `TARGETS > Runner > Build Settings > Search Paths > Library Search Paths`.
6. Remove App sand box in `TARGETS > Signing & Capabilities` if you want to set as system proxy.
7. Set `TARGETS > Runner > Build Settings > Architectures > Architectures` into `x86_64` (because libclash.dylib is only built for x86_64).

## Windows
1. Add these into `windows/CMakeList.txt`, the `PATH_TO_LIBCLASH.DLL` typically is `../fclash/dist/libclash.dll`.
    ```cmake
    # Install libclash
    install(FILES "PATH_TO_LIBCLASH.DLL" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
    ```

## Android
1. Set `minSdkVersion` to `19` in app-level `build.gradle`.
2. Modify app-level `build.gradle`
    ```gradle
    android {
        defaultConfig {
            ndk {
                abiFilters 'arm64-v8a', 'armeabi-v7a'
            }
            // ...
        }
        // ...
    }
    ```

## iOS
* Recommend to set all targets `Minimum Developments` >= `15.0` due to the 15MB RAM limitation on lower iOS.
### Create & Setup Targets
1. Create a `NetworkExtension` target named `PacketTunnel`, the XCode will auto create a file named `PacketTunnelProvider.swift`.
2. Create a `Framework` target named `ClashClient`, the XCode will auto create a Group(folder) named `ClashClient`.
3. Add `LibClash.xcframework` into project by right click on `Project Navigator > Runner > Frameworks` and select `Add Files to "Runner"`, with Copy if needed checked.
4. Add `ClashClient.framework` into `TARGET > Runner > General > Frameworks, Libraries, and Embedded content` with `Embed & Sign`.
5. Add `ClashClient.framework` into `TARGET > PacketTunnel > General > Frameworks, Libraries, and Embedded content` with `Do Not Embed`.
6. Add `PacketTunnel.appex` into `TARGET > Runner > General > Frameworks, Libraries, and Embedded content` with `Embed Without Signing`.
7. Add `Libclash.xcframework` into `TARGET > ClashClient > General > Frameworks, Libraries, and Embedded content` with `Do Not Embed`.
8. Add `Tun2SocksKit-main` into `PacketTunnel` by `Swift Package Manager (SPM)` from https://github.com/EbrahimTahernejad/Tun2SocksKit with both `Tun2SocksKit` and `Tun2SocksKitC` libs.
9.  Add `Network Extension` both in `Runner` and `PacketTunnel`'s `Signing & Capabilities` tab.
    * Check `Packet Tunnel`.
10. Add `App Groups` both in `Runner` and `PacketTunnel`'s `Signing & Capabilities` tab.
    * Check `group.<yourBundleId>`
11. Check all targets' `Minimum Developments` are the same.

### Copy & Modify Files
1. Delete `ClashClient/ClashClient.h`.
2. Copy and add all files of `example/ios/ClashClient/` to `ClashClient` target.
3. Copy and add all files of `example/ios/ClashService/` to `Runner` target.
4. Copy `example/ios/PacketTunnel/PacketTunnelProvider.swift` to `PacketTunnel` target.
5. Modify `AppDelegate.swift`
   * Add ```MethodHandler.register(with: self.registrar(forPlugin: MethodHandler.name)!)```.
   ```swift
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
    ```

**Some features on iOS may be difference to other platform**  
**because Clash must be running on `Network Extensions`**  
**so I made a dummy Clash running on App for yaml resolving, delay testing, and a true Clash running on Network Extension for packet tunneling**  

**unsupported features**
- [x] startLog/stopLog (no logStream, only in Console.app)
- [x] getConnection
- [x] closeConnection
- [x] closeAllConnection  

## FAQ
### iOS build error: Cycle inside Runner; building could produce unreliable results.
* Move `Embed Foundation Extensions` above to `Run Script` in `Runner`'s `Build Phases`.
### iOS run with extremely lag
* Edit Scheme, uncheck `Debug executable`(but will cause `flutter run` failure).