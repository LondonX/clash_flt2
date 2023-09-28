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
* Add `libclash.dylib` into `Runner/Frameworks` (you can uncheck `Copy items if needed` if you want).
* Set to `Embed & Sign` of `libclash.dylib` in `TARGETS > Runner > General > Frameworks, Libraries, and Embedded content`.
* Add `libclash.dylib` into `TARGETS > Runner > Build Phases > Copy Bundle Resources`.
* Change the status of `libclash.dylib` into `Optional` in `TARGETS > Runner > Build Phases > Link Binary With Libraries`.
* Add path which `libclash.dylib` can be found at (typically `$(PROJECT_DIR)/../fclash/dist`) into `TARGETS > Runner > Build Settings > Search Paths > Library Search Paths`.
* Remove App sand box in `TARGETS > Signing & Capabilities` if you want to set as system proxy.

## Windows
* Add these into `windows/CMakeList.txt`, the `PATH_TO_LIBCLASH.DLL` typically is `../fclash/dist/libclash.dll`.
    ```cmake
    # Install libclash
    install(FILES "PATH_TO_LIBCLASH.DLL" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
    ```