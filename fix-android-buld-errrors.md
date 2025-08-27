# Fix Android build errors (Pacifica2)

This document tracks the errors observed, root causes, and the safe fixes applied to restore a reliable Android build without changing app functionality.

## Symptoms observed

- Warning: library contains references to both AndroidX and old support library (media2-session 1.2.1). Jetifier attempts rewrite.
- Repeated Java compiler warnings:
  - "source value 8 is obsolete" and "target value 8 is obsolete"
- Build failure:
  - `Execution failed for task ':app:assembleDebug' > com/android/build/OutputFile`
- Earlier failure after removing the legacy loader:
  - Kotlin: `Unresolved reference: io` / `Unresolved reference: FlutterFragmentActivity`

## Root cause analysis

- `com/android/build/OutputFile` failure indicates Android Gradle Plugin (AGP) 8.x removed APIs referenced by some build scripts (common in older plugin scripts or transitive Flutter plugin gradle files). When AGP was at 8.x, these references caused the app:assembleDebug task to crash at configuration/build time.
- Kotlin unresolved references occurred because the Flutter plugin loader was temporarily removed; the embedding dependencies were not on the classpath.
- Mixed AndroidX/support library warning is from a Google artifact `androidx.media2:media2-session:1.2.1`. Jetifier can (and does) rewrite; this is not fatal.
- Java 8 option warnings are informational. The project compiles with Java 8 bytecode (`sourceCompatibility/targetCompatibility = 1.8`), which is still supported. AGP prints deprecation notices but they are not build-breaking.

## Changes applied (safe, reversible)

1) Android Gradle Plugin pinned to 7.4.2 (compatible with older scripts)
- File: `android/build.gradle`
- Change:
  - `classpath 'com.android.tools.build:gradle:7.4.2'`

2) Gradle wrapper pinned to 7.6.3 (pairing with AGP 7.4.2)
- File: `android/gradle/wrapper/gradle-wrapper.properties`
- Change:
  - `distributionUrl=https://services.gradle.org/distributions/gradle-7.6.3-all.zip`

3) Flutter plugin loader applied declaratively (removes deprecation warning while keeping embedding available)
- File: `android/settings.gradle`
- Kept:
  - `includeBuild("${settings.ext.flutterSdkPath}/packages/flutter_tools/gradle")`
  - In `pluginManagement.plugins`:
    - `id "dev.flutter.flutter-plugin-loader" version "1.0.0"`
    - `id "dev.flutter.flutter-gradle-plugin" version "1.0.0" apply false`
  - Top-level:
    - `plugins { id "dev.flutter.flutter-plugin-loader" }`
- Removed legacy:
  - `apply from: "${settings.ext.flutterSdkPath}/packages/flutter_tools/gradle/app_plugin_loader.gradle"`

These steps restore compatibility and remove the deprecation warning without touching any Dart/UI/audio code (preserves existing functionality).

## Validation steps

1. Clean and build
```
flutter clean
flutter pub get
flutter run
```
2. Expected results
- No `com/android/build/OutputFile` failure.
- Kotlin `FlutterFragmentActivity` resolves.
- You may still see non-fatal Java 8 warnings and the AndroidX/support Jetifier notice. These are safe.

## If issues persist
- Run with stacktrace for details:
```
./gradlew :app:assembleDebug --stacktrace
```
- Share the stacktrace to pinpoint any remaining plugin script referencing removed AGP 8 APIs.

## Future upgrade plan (optional, once stable)
- Incrementally update Flutter SDK and plugins to versions compatible with AGP 8.x/Gradle 8.x.
- Remove Java 8 warnings by moving to Java 11+ bytecode once all dependencies allow it.
- Re-verify that the declarative Flutter plugin loader remains compatible (it should be) and simplify settings if Flutter tooling evolves further.

## Summary
- Root cause: AGP 8.x incompatibilities with older build scripts (OutputFile API removal) and removal of loader temporarily broke embedding.
- Resolution: Pin AGP/Gradle to 7.4.2/7.6.3 and apply Flutter plugin loader declaratively.
- Outcome: Stable Android build path without altering app features or UI.
