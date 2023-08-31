# Clash PC for flutter
A Flutter plugin of Clash, support Mac OS and Windows.  

Extract clash core from [FClash](https://github.com/Fclash/Fclash).  
Using [ffigen](https://pub.dev/packages/ffigen) to create bridge tween clash core and dart.  

# Build libs
* requires Golang >= 1.2
```shell
cd fclash
./build_libclash.sh
```
It will create `libclash.dll`, `libclash.dylib`, `libclash.so` and `libclash.h` in `fclash/dist` directory.

# Run ffigen
* requires LLVM ([Installing LLVM](https://pub.dev/packages/ffigen#installing-llvm))
```shell
dart run ffigen
```

# Platform works
## Mac OS
* Add `libclash.dylib` into `Runner/Frameworks` (you can uncheck `Copy items if needed` if you want).
* Set to `Embed & Sign` of `libclash.dylib` in `TARGETS > Runner > General > Frameworks, Libraries, and Embedded content`.
* Add `libclash.dylib` into `TARGETS > Runner > Build Phases > Copy Bundle Resources`.
* Add path which `libclash.dylib` can be found at (typically `$(PROJECT_DIR)/../fclash/dist`) into `TARGETS > Runner > Build Settings > Search Paths > Library Search Paths`.
* Remove App sand box in `TARGETS > Signing & Capabilities` if you want to set as system proxy.