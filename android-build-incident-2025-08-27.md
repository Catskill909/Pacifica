# Android Build Incident Report — Pacifica2 (2025-08-27)

## Summary
- Goal: Fix Android build errors while preserving all UI/behavior.
- We attempted two toolchain tracks:
  - Modern stack: AGP 8.2.1 + Gradle 8.5 + compileSdk 34 → fails with `ClassNotFoundException: com.android.build.OutputFile` during `:app:assembleDebug`.
  - Legacy stack: AGP 7.4.2 + Gradle 7.6.3 + compileSdk 33 → avoids the removed API, but then dependencies require compileSdk 34 and AAPT2 crashes appear if we force 33.
- Root issue: Some Gradle logic (in a plugin or build script) still references AGP’s removed `OutputFile` API. Downgrading AGP sidesteps that removal but conflicts with dependency requirements for SDK 34.

## Timeline (UTC-4)
- 11:30–11:40: Downgraded to AGP 7.4.2 + Gradle 7.6.3 to bypass OutputFile removal. Build began failing at resource link step with AAPT2 NPE (`RelativeResourceUtils.getRelativeSourceSetPath`).
- 11:43: Rolled forward to AGP 8.2.1 + Gradle 8.5 → failure with `ClassNotFoundException: com.android.build.OutputFile` during `:app:assembleDebug`.
- 11:50: Re-downgraded to AGP 7.4.2 + Gradle 7.6.3 and pinned compileSdk/targetSdk to 33 → dependency checks fail: multiple AndroidX/Flutter plugins require compileSdk 34.

## Errors Observed
- AGP 8.x path:
  - `Caused by: java.lang.ClassNotFoundException: com.android.build.OutputFile` (during assemble).
  - Indicates some Gradle code still calls a class removed in AGP 8.
- AGP 7.4.x path:
  - AAPT2 resource link crash during `:app:processDebugResources` (NPE while rewriting error positions) — typically masks an underlying resource or configuration issue, but also observed when mixing modern dependencies with older AGP.
  - Plugins and AndroidX require compileSdk 34. AGP 7.4 recommends max compileSdk 33 → version conflict.

## Environment/Config as tested
- `android/build.gradle` (varied): AGP 7.4.2 vs 8.2.1
- `android/gradle/wrapper/gradle-wrapper.properties`: Gradle 7.6.3 vs 8.5
- `android/app/build.gradle`:
  - When on AGP 7.4.2: compileSdk 33, targetSdk 33 (to satisfy AGP limits) → dependency failures (plugins require 34).
  - When on AGP 8.2.1: compileSdk 34 → OutputFile ClassNotFound.
- Plugins in pubspec include: `webview_flutter`, `audio_service`, `just_audio`, `connectivity_plus`, `url_launcher`, etc. They (and AndroidX core 1.13.1) expect compileSdk 34.

## Root-Cause Hypothesis
- A Gradle script (either from Flutter tooling or a third-party plugin) still references AGP pre-8 APIs (`com.android.build.OutputFile`, often via `variant.outputs` logic for APK file naming). Under AGP 8.x this throws ClassNotFound. Under AGP 7.4 it “works” but collides with dependencies that require SDK 34.
- Candidate sources:
  1) Older Flutter Gradle plugin (if the installed Flutter SDK is pre-AGP8-ready).
  2) A Flutter plugin’s `android/build.gradle` that manipulates variants/outputs.
  3) Legacy code in the app-level Gradle files (we scanned and didn’t find such references).

## Decision & Strategy
1) Restore the last known working commit to stabilize and unblock development.
2) On a branch, move forward with the modern toolchain (AGP 8.2.1 + Gradle 8.5 + compileSdk 34) because plugin and AndroidX dependencies require it.
3) Identify and remediate the single offending dependency/build script that still uses OutputFile-era APIs:
   - Upgrade the plugin to a version compatible with AGP 8.
   - If no update exists, patch the plugin’s Gradle script to remove `variant.outputs`/`OutputFile` usage (or use a fork).
   - If the offender is the Flutter SDK plugin (older Flutter), update Flutter to a version whose Gradle tooling supports AGP 8.

## Validation Checklist (must remain true)
- Play/Pause button position and behavior unchanged.
- Top section images/icons unchanged.
- Main content (WebView) unchanged; Donate opens in external browser.
- Only build tooling/dependency adjustments; no UI code changes.

## Action Plan (proposed)
1) Hard reset to last good commit (baseline restore).
2) Create a new branch `build/tooling-upgrade`.
3) Diagnostics on that branch:
   - Capture Flutter version.
   - Grep the Flutter Gradle tooling and the local pub cache for `com.android.build.OutputFile`, `variant.outputs`, `applicationVariants` occurrences.
4) Apply fix:
   - If a plugin is the source: upgrade or patch it; confirm assembly succeeds on AGP 8.2.1 / SDK 34.
   - If Flutter SDK tooling is the source: upgrade Flutter and re-try.
5) Verify builds and run-device tests. Document the exact fix and lock versions.

## Notes
- Downgrade paths cause cascading incompatibilities due to modern AndroidX and Flutter plugins targeting SDK 34. The stable long-term solution is to stay on AGP 8.x and fix the single consumer of the removed API.

## Appendices
- Sample errors:
  - AGP 8.x: `ClassNotFoundException: com.android.build.OutputFile`
  - AGP 7.4.x: AAPT2 link crash and plugin warnings: "requires Android SDK version 34" for `connectivity_plus`, `just_audio`, `path_provider_android`, `sqflite_android`, `url_launcher_android`, `webview_flutter_android`.

---

## Recovery Status (2025-08-27 12:10 ET)

* __Repo reset__: Hard reset to `origin/main` completed and tagged `pre-reset-2025-08-27` for safety.
* __Baseline build__: `./gradlew clean && :app:assembleDebug` succeeded on AGP 8.2.1 / Gradle 8.5 with a warning that compileSdk=35 is above AGP’s tested range (AGP 8.2.1 tested up to 34). No OutputFile crash reproduced at baseline.
* __Diagnostics__: Grepped project and pub cache for `com.android.build.OutputFile`, `variant.outputs`, `applicationVariants`, `outputFileName` → none found. This suggests the prior OutputFile failure stemmed from temporary local changes rather than a persisted plugin.
* __Current state__: Functional baseline restored. Keep existing UI/behavior unchanged.

### Next Steps (tracked)
1. Keep modern toolchain: AGP 8.2.1 + Gradle 8.5; Flutter currently sets compileSdk to 35 (warning only). Consider upgrading AGP later to a version tested with 35 to remove the warning.
2. Defer migration from imperative `app_plugin_loader` to declarative plugins block until after a full QA run; when attempted, do it on a branch and verify builds.
3. If the OutputFile error reappears during modernization, re-run diagnostics and isolate the change that triggers it.

