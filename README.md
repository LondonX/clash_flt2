# Clash PC for flutter
A Flutter plugin of Clash, support Mac OS and Windows.  

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
    dist/libclash.dll:   PE32+ executable (DLL) (console) x86-64 (stripped to external PDB), for MS Windows
    dist/libclash.dylib: Mach-O 64-bit dynamically linked shared library x86_64
    dist/libclash.so:    ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, Go BuildID=********, stripped
    ```
* It will create `libclash.dll`, `libclash.dylib`, `libclash.so` and `libclash.h` in `fclash/dist` directory.

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
1. Same step 1~5 of `Mac OS` with `libclash-ios.dylib` file.
2. Set `TARGETS > Runner > General > Minimum Developments` >= `15.0`
3. Create a Target named `PacketTunnel`, the XCode will auto create a file named `PacketTunnelProvider.swift`.
4. Modify the `PacketTunnel`
    * Modify `PacketTunnelProvider.swift` by paste from [Example's PacketTunnelProvider.swfit](example/ios/PacketTunnel/PacketTunnelProvider.swift)
    * Copy `ClashBridge.swift` from [Example's ClashBridge.swfit](example/ios/PacketTunnel/ClashBridge.swift)
    * Add `Tun2SocksKit-main` by `Swift Package Manager (SPM)` from https://github.com/arror/Tun2SocksKit or `<project-root>/ios/Tun2SocksKit-main`.
    * Add `Tun2SocksKit` lib into `Frameworks and Libraries` of `PacketTunnel` target.
    * (Optional) Add `HevSocks5Tunnel.xcframework`
5. Add `Network Extension` both in `Runner` and `PacketTunnel`'s `Signing & Capabilities` tab.
    * Check `Packet Tunnel`.
6. Add `App Groups` both in `Runner` and `PacketTunnel`'s `Signing & Capabilities` tab.
    * Check `group.<yourBundleId>`

**Some features on iOS may be difference to other platform**  
**because Clash must be running on `Network Extensions`**  
**so I made a dummy Clash running on App for yaml resolving, delay testing, and a true Clash running on Network Extension for packet tunneling**  

**unsupported features**
- [ ] startLog/stopLog
- [ ] getConnection
- [ ] closeConnection
- [ ] closeAllConnection  

## FAQ
### iOS build error: Cycle inside Runner; building could produce unreliable results.
* Mode `Embed Foundation Extensions` above to `Run Script` in `Runner`'s `Build Phases`.