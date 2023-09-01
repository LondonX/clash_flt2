#!/bin/bash
MACOSX_DEPLOYMENT_TARGET=13.0
MACOS_EXT_FLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

# MacOS
echo "Building libclash.dylib"
GOOS=darwin CGO_ENABLED=1 GOARCH=amd64 go build -ldflags="-w -s -extldflags=$MACOS_EXT_FLAGS" -buildmode=c-shared -o ./dist/libclash.dylib

# Windows
echo "Building libclash.dll"
GOOS=windows CGO_ENABLED=1 GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/libclash.dll

# Linux
echo "Building libclash.so"
GOOS=linux CGO_ENABLED=1 GOARCH=amd64 CC=x86_64-linux-musl-gcc  CXX=x86_64-linux-musl-g++ go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/libclash.so

file dist/libclash.dll dist/libclash.dylib dist/libclash.so