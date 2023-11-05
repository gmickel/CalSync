# Release Process
1. Archive from XCode
2. Sign the binary `codesign -f -o runtime --entitlements entitlements.plist --timestamp -s "Developer ID Application: Thomas Preece (GKK3S8K4V3)" CalSync\ 2023-11-04\ 16-23-23/Products/usr/local/bin/CalSync`
3. Build the package `pkgbuild --root "CalSync 2023-11-04 16-23-23/Products" --identifier "com.tpreece101.calsync" --version "0.1.1" --install-location "/" --sign "Developer ID Installer: Thomas Preece (GKK3S8K4V3)" calsync-0.1.1.pkg`
4. Notarise the package `xcrun notarytool submit calsync-0.1.1.pkg --keychain-profile "notary-profile" --wait`
5. Attach identity `xcrun stapler staple calsync-0.1.1.pkg`
