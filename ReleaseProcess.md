
# Release Process

1. Archive from Xcode
   - Select Product > Archive
   - Note the created archive path (e.g., `CalSync 2025-01-09 00.19.xcarchive`)

2. Sign the binary:
   ```bash
   codesign -f -o runtime --entitlements entitlements.plist --timestamp -s "[Your Developer ID Application Certificate]" /path/to/archive/CalSync.xcarchive/Products/usr/local/bin/CalSync
   ```

3. Build the package:
   ```bash
   pkgbuild --root "/path/to/archive/CalSync.xcarchive/Products" \
            --identifier "tech.mickel.calsync" \
            --version "0.2.0" \
            --install-location "/" \
            --sign "[Your Developer ID Installer Certificate]" \
            calsync-0.2.0.pkg
   ```

4. Notarize the package:
   ```bash
   xcrun notarytool submit calsync-0.2.0.pkg --keychain-profile "[Your Notarization Profile]" --wait
   ```

5. Attach identity:
   ```bash
   xcrun stapler staple calsync-0.2.0.pkg
   ```

Note: 
- Replace placeholders in square brackets with your actual credentials
- Keep your certificates and profile information secure
- Never commit actual certificate or profile details to the repository
