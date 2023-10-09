#!/bin/bash
rm -rf dist

MACOSX_DEPLOYMENT_TARGET=13.0
MACOS_EXT_FLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

# MacOS
echo "Building libclash.dylib"
GOOS=darwin CGO_ENABLED=1 go build -ldflags="-w -s -extldflags=$MACOS_EXT_FLAGS" -buildmode=c-shared -o ./dist/libclash.dylib

# Windows
echo "Building libclash.dll"
GOOS=windows CGO_ENABLED=1 GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/libclash.dll

# Android
echo "Building Android libclash.so"
echo "  > Build for armeabi-v7a"
GOOS=android CGO_ENABLED=1 GOARCH=arm GOARM=7 CC=/Users/london/Library/Android/sdk/ndk/26.0.10792818/toolchains/llvm/prebuilt/darwin-x86_64/bin/armv7a-linux-androideabi26-clang go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/android/armeabi-v7a/libclash.so
echo "  > Build for arm64-v8a"
GOOS=android CGO_ENABLED=1 GOARCH=arm64 CC=/Users/london/Library/Android/sdk/ndk/26.0.10792818/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/android/arm64-v8a/libclash.so

# iOS
echo "Building iOS libclash-ios.dylib"
# xcrun -sdk iphoneos clang -arch arm64
GOOS=ios CGO_ENABLED=1 GOARCH=arm64 CC="clang -arch arm64 -miphoneos-version-min=15.0 -isysroot $(xcrun -sdk iphoneos --show-sdk-path)" go build -ldflags="-w -s" -buildmode=c-archive -o ./dist/libclash-ios.a
xcrun -sdk iphoneos clang -arch arm64 -shared -Wl,-all_load ./dist/libclash-ios.a -framework CoreFoundation -framework Security -o ./dist/libclash-ios.dylib

# Merge .h files print the build result
find . -name "libclash*.h" -exec mv {} ./dist/libclash.h \;
find . -name "libclash*.*" -exec file {} \;