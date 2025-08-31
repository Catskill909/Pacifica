# KEYSTORE REPLACEMENT STEPS

## When Pacifica provides the original keystore:

### 1. Replace Current Keystore
```bash
cd /Users/paulhenshaw/Desktop/Pacifica2/android/keystore
# Backup current keystore
mv upload-keystore.jks upload-keystore-backup.jks
# Copy Pacifica's original keystore
cp /path/to/pacifica/original-keystore.jks upload-keystore.jks
```

### 2. Update keystore.properties
```
storePassword=PACIFICA_KEYSTORE_PASSWORD
keyPassword=PACIFICA_KEY_PASSWORD
keyAlias=PACIFICA_KEY_ALIAS
storeFile=../keystore/upload-keystore.jks
```

### 3. Verify Certificate Fingerprint
```bash
keytool -list -v -keystore upload-keystore.jks -storepass PASSWORD | grep SHA1
# Should show: 41:2B:E6:C3:80:E4:B8:29:3F:D3:F8:03:AA:FC:C5:BD:90:E1:FF:1E
```

### 4. Rebuild and Upload
```bash
flutter build appbundle --release
# Upload build/app/outputs/bundle/release/app-release.aab
```

## Current Status:
- Package name: com.kpft.radio2025
- App ready for build
- Waiting for Pacifica's original keystore
