# KPFT Pacifica Android Upload Keystore (Created 2025-08-31)

IMPORTANT: This file contains sensitive credentials. Share only with trusted team members. Do not commit to public repositories.

## Keystore Summary
- Keystore file: `android/keystore/kpft-pacifica-upload.jks`
- Key alias: `kpftpacifica2025`
- Store password: `ea427881c3630197732c38694b7d0334`
- Key password: Same as store password (PKCS12 uses one password)
- Key algorithm: RSA 4096-bit
- Signature algorithm: SHA384withRSA
- Validity: 2025-08-31 to 2053-01-16
- Distinguished Name (DN): `CN=KPFT, OU=Development, O=Pacifica Foundation, L=Houston, ST=TX, C=US`

## Certificate Fingerprints (Verified)
- SHA1: DE:AE:80:4D:E6:9A:85:DA:6A:E8:9F:7B:F1:3C:0F:52:54:DB:94:99
- SHA256: 2D:94:7C:97:D2:60:AC:02:65:77:B9:AC:F0:41:80:16:8B:C5:25:09:A3:24:50:59:94:81:5D:27:BD:D6:3B:C1
- Created: 2025-08-31 12:33 EDT

## Project Configuration
The project is already configured to use this keystore:
- File: `android/keystore.properties`
- Contents:
  - `storeFile=../keystore/kpft-pacifica-upload.jks`
  - `keyAlias=kpftpacifica2025`
  - `storePassword=ea427881c3630197732c38694b7d0334`
  - `keyPassword=ea427881c3630197732c38694b7d0334`

Android Gradle reads these values in `android/app/build.gradle` under `signingConfigs.release`.

## Usage Instructions
1. Build a release AAB after a clean:
   - `flutter clean`
   - `flutter build appbundle --release`
2. Verify the AAB is signed with this keystore (optional, recommended):
   - Keystore SHA1:
     - `keytool -list -v -keystore android/keystore/kpft-pacifica-upload.jks -alias kpftpacifica2025 -storepass 'ea427881c3630197732c38694b7d0334'`
   - AAB certificate:
     - `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`
   - The AAB's SHA1 should match the keystore's SHA1 (do not use any Play Console "expected" value).
3. Upload the AAB to Google Play Console using a clean browser profile logged into the Pacifica developer account only.

## Security Notes
- Store this file and the `.jks` securely (password manager + secure storage).
- Do not email passwords in plain text.
- Do not commit the `.jks` file or this document to any public repository.

## Contact
Pacifica Developer Team
