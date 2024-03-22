#!/bin/bash
rm -rf dist

# iOS
echo "Building iOS Libclash.xcframework"
gomobile bind -target=ios/arm64 -o ./dist/Libclash.xcframework