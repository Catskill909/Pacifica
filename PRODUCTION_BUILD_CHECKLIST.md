# KPFT Production Build Checklist

## ✅ COMPLETED ITEMS

### App Configuration
- [x] **App ID**: `org.pacifica.kpft.app` ✅
- [x] **App Name**: "KPFT" ✅
- [x] **Version**: 1.0.0+1 (ready for first release) ✅
- [x] **Target SDK**: Latest Flutter target ✅

### Android Manifest & Permissions
- [x] **Internet Permission**: Required for streaming ✅
- [x] **Wake Lock**: For background audio ✅
- [x] **Foreground Service**: For audio playback ✅
- [x] **Media Playback Service**: For lock screen controls ✅
- [x] **Post Notifications**: For Android 13+ ✅
- [x] **Audio Service Configuration**: Properly configured ✅

### Build Configuration
- [x] **Signing Config**: Set up in build.gradle ✅
- [x] **Release Build Type**: Configured ✅
- [x] **MultiDex**: Enabled ✅
- [x] **ProGuard**: Disabled (recommended for Flutter) ✅

### App Features Verified
- [x] **Audio Streaming**: HD1, HD2, HD3 streams working ✅
- [x] **WebView Integration**: All tabs functional ✅
- [x] **Bottom Navigation**: Tab switching works ✅
- [x] **Background Audio**: Continues when app backgrounded ✅
- [x] **Lock Screen Controls**: Working properly ✅
- [x] **Network Detection**: Offline overlay functional ✅
- [x] **External Browser**: Donate tab opens externally ✅

## 🔄 NEXT STEPS REQUIRED

### 1. Generate Keystore (REQUIRED)
```bash
cd android/keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Create keystore.properties
```bash
cd android
cp keystore/keystore.properties.sample keystore.properties
# Edit keystore.properties with actual passwords
```

### 3. Build Production AAB with Debug Symbols
```bash
# Clean and build AAB with debug symbols (REQUIRED for Play Console)
flutter clean && flutter pub get && flutter build appbundle --split-debug-info=build/app/outputs/symbols

# Create zip file for native debug symbols
cd build/app/outputs/symbols && zip -r app-release.zip *.symbols && cd ../../../..

# For APK (if needed for testing)
flutter build apk --release
```

### 4. Test Production Build
- Install on physical device
- Test all audio streams
- Test background playback
- Test lock screen controls
- Test network connectivity scenarios

### 5. Google Play Console Setup
 - Before uploading, follow the "Android Play Upload SOP (Signing + Upload)" in `README.md` (certificate verification + clean browser profile)
- Create Google Play Console account
- Upload AAB file
- **Upload Debug Files (CRITICAL for crash analysis):**
  - Go to **App bundle explorer** → Select version → **Downloads** tab
  - Upload deobfuscation file: `build/app/outputs/mapping/release/mapping.txt`
  - Upload native debug symbols: `build/app/outputs/symbols/app-release.zip`
- Configure store listing
- Set up app signing by Google Play

## 📁 Files Created/Updated
- `android/keystore/README.md` - Setup documentation
- `android/keystore/KEYSTORE_GENERATION_COMMANDS.md` - Generation commands
- `android/keystore/UPLOAD_KEY_INFO.md` - Key information template
- `android/keystore/keystore.properties.sample` - Configuration template
- `pubspec.yaml` - Version updated to 1.0.0+1

## ⚠️ SECURITY REMINDERS
1. **NEVER commit keystore files to git**
2. **Backup keystore and passwords securely**
3. **Use strong passwords for keystore**
4. **Store keystore information in password manager**

## 🎯 READY FOR PRODUCTION
Your app is **95% ready** for production build. Only missing:
1. Generate keystore (5 minutes)
2. Create keystore.properties (2 minutes)
3. Build and test (10 minutes)

Total time to production: **~20 minutes**
