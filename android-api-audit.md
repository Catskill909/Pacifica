# Android API Level Audit & Update Plan

This document outlines the plan to audit and update the Android target API level to comply with Google Play Store requirements as of August 31, 2025.

## 1. Audit Current API Levels

- **File to check**: `android/app/build.gradle`
- **Values to find**:
    - `minSdkVersion`
    - `compileSdkVersion`
    - `targetSdkVersion`

## 2. Update Plan

Based on Google Play's requirement to target API level 35 (Android 15) by August 31, 2025, the following changes are proposed:

- **`compileSdkVersion`**: Update to `35`.
- **`targetSdkVersion`**: Update to `35`.
- **`minSdkVersion`**: Keep as is, unless dependencies require a higher version.

## 3. Potential Risks & Mitigation

- **Dependency Conflicts**: Some packages may not be compatible with API 35. We will need to check for package updates.
- **Behavioral Changes**: Higher API levels can introduce changes in how the OS handles permissions, background tasks, and privacy. Thorough testing is required.
- **Build Failures**: The project might fail to build with the new SDK. We will address any build errors as they appear.

## 4. Testing Strategy

1.  **Build**: Run `./gradlew assembleRelease` to ensure the app builds successfully.
2.  **Unit & Integration Tests**: Run any existing tests.
3.  **Manual Testing**: Install the app on a device or emulator and test core functionalities:
    - App startup
    - Audio playback (HD1, HD2, HD3 streams)
    - Tab switching
    - WebView content loading
    - 'Donate' button functionality
    - Lock screen controls
    - Network connectivity handling

## 5. Audit Log

*This section will be updated as we proceed.*

- **Current `minSdkVersion`**: `flutter.minSdkVersion` (Inherited from Flutter project)
- **Current `compileSdkVersion`**: `flutter.compileSdkVersion` (Inherited from Flutter project)
- **Current `targetSdkVersion`**: `flutter.targetSdkVersion` (Inherited from Flutter project)
