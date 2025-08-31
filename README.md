# Pacifica - KPFT 90.1 FM Mobile App

A Flutter-based mobile application for KPFT 90.1 FM, Houston's Community Station. This app is designed to provide live streaming, news updates, and community engagement features.

## AI-Enhanced Development

This application has been developed with the assistance of advanced AI tools, embracing modern software development practices that combine human expertise with AI capabilities. The codebase is structured to support continued AI-assisted development, featuring:

- Clear documentation and consistent code patterns that facilitate AI comprehension
- Modular architecture designed for easy future enhancements
- Well-documented configuration files that enable AI-assisted customization
- Semantic commit messages and code comments that enhance AI-human collaboration

This approach ensures that future development can efficiently leverage AI assistance while maintaining code quality and project consistency.

## Features

### 1. Live Radio Streaming
- High-quality audio streaming of KPFT 90.1 FM
- Background audio playback support
- Media controls integration with system notifications
- Automatic stream recovery on connection issues

### 2. News Integration
- Real-time news updates from KPFT's WordPress site
- Clean, readable article layout
- Support for rich media content (images, videos)
- Easy navigation between articles

### 3. WebView Integration
- Embedded web content from KPFT's digital platforms
- Responsive layout adaptation
- Loading indicators for better user experience
- Error handling with automatic reload capability

### 4. Interactive Bottom Sheet
- Quick access to additional station features
- Dynamic content loading
- Customizable grid layout for navigation buttons
- Social media integration

## In-Progress Development

### Package Updates Needed
- Several packages have newer versions available that need to be evaluated and updated:
  - 59 packages have newer versions available
  - `just_audio_mpv` is discontinued and should be replaced with `just_audio_media_kit`
  - Key updates include:
    - Flutter core packages (async, collection, etc.)
    - Audio-related packages (audio_service, just_audio)
    - UI packages (flutter_launcher_icons, flutter_native_splash)
    - Platform-specific packages (webview_flutter, url_launcher)

### Configuration File
- A central configuration file (`config.md`) has been created to facilitate easy reskinning of the app. This file includes:
  - Images
  - Titles and Headers
  - Audio Stream Configuration
  - WordPress API Configuration
  - Social Media Links
  - Styling options (colors, fonts)

### Metadata from Pacifica API
- The app will utilize metadata from the Pacifica API for lock screen and notification tray features. This includes:
  - Song playing image
  - Song playing title
  - Show title
  - Show time
  - Next show playing

### Core Components

- `main.dart`: Main application entry point and audio service initialization
- `webview.dart`: Custom WebView implementation with error handling
- `wordpres.dart`: WordPress integration for news content
- `sheet.dart`: Bottom sheet UI and functionality
- `social.dart`: Social media integration
- `vm.dart`: View models and data management

### Key Dependencies

- `audio_service`: Background audio playback
- `just_audio`: Audio playback engine
- `webview_flutter`: Web content display
- `http`: API communication
- `url_launcher`: External link handling
- `cached_network_image`: Image caching and loading

## Debugging Guidelines

⚠️ **CRITICAL**: When debugging recent regressions, always start with timeline analysis and git history.

See `debugging-struggle-analysis.md` for detailed lessons learned from a 4-hour debugging session that could have been resolved in 25 minutes with proper methodology.

### Debugging Checklist for Regressions
1. **Listen to timeline context**: "worked before, broke recently" = git history investigation
2. **Check recent commits**: `git log --oneline --since="X days ago"`
3. **Identify breaking changes**: `git show <commit> -- <file>`
4. **Understand before fixing**: Don't apply random fixes without understanding the system
5. **One change at a time**: Test each fix individually

### Common Anti-Patterns to Avoid
- Symptom-focused debugging (hiding problems instead of finding root cause)
- Ignoring user timeline information
- Making assumptions about "standard behavior"
- Applying multiple fixes without understanding
- Creating complex solutions for simple regressions

## Getting Started

1. Ensure you have Flutter installed and set up on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app in debug mode

## Android Play Upload SOP (Signing + Upload)

Use this checklist to avoid Play Console signing issues and ensure clean first uploads.

- **Keystore**
  - Upload keystore: `android/keystore/kpft-pacifica-upload.jks`
  - Alias: `kpftpacifica2025`
  - Details and credentials: see `android/keystore/KPFT_PACIFICA_UPLOAD_KEY_2025.md`

- **Project configuration**
  - Confirm package ID everywhere: `org.pacifica.kpft.app`
    - `android/app/build.gradle` → `namespace` and `applicationId`
    - `android/app/src/main/AndroidManifest.xml` → `package`
    - Kotlin path matches package: `android/app/src/main/kotlin/org/pacifica/kpft/app/MainActivity.kt`

- **Build AAB & Generate Debug Symbols**
  - Run the build command with the `--split-debug-info` flag. This creates the App Bundle (`.aab`), native debug symbols (`.zip`), and the deobfuscation map (`.txt`).
    ```bash
    flutter clean && flutter pub get && flutter build appbundle --split-debug-info=build/app/outputs/symbols
    ```

- **Upload to Play Console**
  1.  **Upload App Bundle**: In the Play Console, upload the App Bundle located at `build/app/outputs/bundle/release/app-release.aab`.
  2.  **Upload Debug Files**: After uploading the bundle, go to the **App bundle explorer**, select the version, and go to the **Downloads** tab.
      - Upload the deobfuscation file: `build/app/outputs/mapping/release/mapping.txt`.
      - Upload the native debug symbols: `build/app/outputs/symbols/app-release.zip`.

- **Verify certificates BEFORE uploading**
  - Keystore (press Enter if prompted for key password):
    ```bash
    keytool -list -v -alias kpftpacifica2025 -keystore android/keystore/kpft-pacifica-upload.jks
    ```
  - AAB signer:
    ```bash
    keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
    ```
  - The AAB SHA1/SHA256 must match the keystore exactly.

- **Known-good upload certificate fingerprints (as of 2025-08-31)**
  - SHA1: `DE:AE:80:4D:E6:9A:85:DA:6A:E8:9F:7B:F1:3C:0F:52:54:DB:94:99`
  - SHA256: `2D:94:7C:97:D2:60:AC:02:65:77:B9:AC:F0:41:80:16:8B:C5:25:09:A3:24:50:59:94:81:5D:27:BD:D6:3B:C1`

- **Upload hygiene (critical)**
  - Use a clean Chrome profile/Incognito.
  - Log in to the correct developer account (Pacifica).
  - Play Console → Testing → Internal testing → Create release → Upload the AAB.
  - Add testers, roll out to internal testing, share opt-in URL.

- **If Play shows “wrong key” on the first upload**
  - Collect evidence and open a support ticket:
    - Screenshot: keystore `keytool -list -v` output (SHA1/SHA256)
    - Screenshot: AAB `keytool -printcert -jarfile ...` output
    - Screenshot: Play error message
  - Note: Final app signing is by Google Play; your AAB must be signed by the upload key only.

Tip: Avoid external cross-project references (e.g., third-party asset URLs) to reduce perceived linkage between projects.