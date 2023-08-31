#!/bin/bash
# CGO_ENABLED=1
# CGO_LDFLAGS="-mmacosx-version-min=10.14"
MACOSX_DEPLOYMENT_TARGET=13.0
MACOS_EXT_FLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
# CGO_CFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

# Windows
go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/libclash.dll

# MacOS
go build -ldflags="-w -s -extldflags=$MACOS_EXT_FLAGS" -buildmode=c-shared -o ./dist/libclash.dylib

# Linux
go build -ldflags="-w -s" -buildmode=c-shared -o ./dist/libclash.so
