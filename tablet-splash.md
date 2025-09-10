# Android Tablet Splash Screen – CRITICAL ANALYSIS AFTER FAILED ATTEMPTS

## CURRENT STATUS: SPLASH RESTORED TO WORKING STATE
- Removed all tablet-specific overrides that caused severe breakage
- Back to original working splash (small logo with border on tablets, perfect on phones)

## FAILED ATTEMPTS AND WHY THEY BROKE:
1. **Android 12+ windowSplashScreenAnimatedIcon**: Caused cropping of large images
2. **Android 12+ windowSplashScreenBrandingImage**: Created duplicate images (tiny + squashed second image)
3. **Resource qualifier overrides (-sw600dp)**: Interfered with existing working system

## ROOT CAUSE ANALYSIS: Why This Is So Difficult

### The Real Problem
- `flutter_native_splash` plugin generates splash resources automatically
- Plugin does NOT generate Android 12+ specific resources by default
- Tablets on Android 12+ fall back to system behavior (app icon, not custom splash)
- Manual Android 12+ overrides conflict with plugin-generated resources

### Why Manual Fixes Failed
- Plugin manages the entire splash system via `pubspec.yaml` configuration
- Manual resource additions create conflicts between plugin and custom resources
- Android 12+ has strict size/positioning rules that differ from pre-12 behavior

## DEEP ANALYSIS: Why Image Is Still Cropped on Tablets

### What the Plugin Generated (Android 12+)
- **Generated styles**: `values-v31/styles.xml` with `android:windowSplashScreenAnimatedIcon`
- **Generated assets**: `drawable-*/android12splash.png` (1024x1024, identical to source)
- **Problem**: `windowSplashScreenAnimatedIcon` has STRICT size limits on Android 12+

### Android 12+ Icon Size Limitations (Root Cause)
```
android:windowSplashScreenAnimatedIcon - MAXIMUM 240dp diameter
```
- On tablets (high DPI): 240dp = ~640px maximum
- Your logo: 1024x1024px 
- **Result**: Android automatically crops/scales down to fit 240dp circle

### Why Phones Look Fine vs Tablets Look Cropped
- **Phones**: Lower DPI, 240dp limit less noticeable
- **Tablets**: Higher DPI, 240dp limit severely crops 1024px image
- **Android 12+ behavior**: System enforces strict circular icon bounds

### The Plugin Configuration (Currently Applied)
```yaml
flutter_native_splash:
  color: "#000000"
  image: assets/kpft.png
  android: true
  ios: true
  android_12:          # ← This generates windowSplashScreenAnimatedIcon
    image: assets/kpft.png
    color: "#000000"
```

### Why This Approach Cannot Work for Large Logos
- `windowSplashScreenAnimatedIcon` is designed for app icons (small, circular)
- Your KPFT logo is a full branding image (large, rectangular content)
- Android 12+ strictly enforces the 240dp circular constraint

## DEFINITIVE ROOT CAUSE FOUND

### What's Actually Happening (Expert Analysis)
Your tablet is running Android 14 (API 34) and showing the **APP ICON** instead of your custom splash image.

**The Problem:**
- Android 12+ requires `android:windowSplashScreenAnimatedIcon` in styles
- Without it, system defaults to `@mipmap/ic_launcher` (your app icon)
- Your app icon: Small (192x192) with green background
- **Result**: Tiny logo with green border (exactly what you're seeing)

### Why Phones Work vs Tablets Don't
- **Phones**: Lower DPI, app icon fallback less noticeable
- **Tablets**: High DPI, app icon looks tiny and obvious

### Current Configuration Issues
```xml
<!-- values-v31/styles.xml - MISSING windowSplashScreenAnimatedIcon -->
<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
    <!-- MISSING: android:windowSplashScreenAnimatedIcon -->
</style>
```

### The Android 12+ Dilemma
- **Need**: `windowSplashScreenAnimatedIcon` to show custom image
- **Problem**: 240dp size limit crops your 1024x1024 logo
- **Current**: No icon specified = defaults to tiny app icon

## FINAL SOLUTION: Create Properly Sized Android 12+ Icon

### The Fix
Create a tablet-optimized splash icon that fits within Android 12+ constraints:

1. **Design constraint**: 240dp diameter circle
2. **Tablet resolution**: ~640px maximum
3. **Solution**: Create simplified logo version for Android 12+ only

## How the splash is currently implemented (Android)
- Plugin configured in `pubspec.yaml`:
  - `flutter_native_splash` set with `color: "#000000"` and `image: assets/kpft.png`.
  - See: `pubspec.yaml` lines 57–65.
- Pre‑Android 12 theme uses a layered drawable:
  - `android/app/src/main/res/drawable/launch_background.xml` and `drawable-v21/launch_background.xml`:
    - Background: `@drawable/background` with `android:gravity="fill"` (a 1×1 black PNG stretched to fill).
    - Foreground: `@drawable/splash` with `android:gravity="center"`.
- Splash image variants present:
  - `android/app/src/main/res/drawable-*/splash.png` (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).
  - There is also `drawable/splashscreen.png` (not referenced by `launch_background.xml`).
- Android 12+ (API 31+) styles:
  - `android/app/src/main/res/values-v31/styles.xml` and `values-night-v31/styles.xml` exist, but they do NOT set any of the Android 12 splash-specific attributes like `android:windowSplashScreenAnimatedIcon` or `android:windowSplashScreenBackground`.
  - This typically means Android 12+ devices fall back to system defaults (often using the app icon) instead of our custom bitmap for the splash.

## Why tablets show a small logo with a faint border
- Android 12+ behavior on devices without explicit `windowSplashScreen*` configuration:
  - The system shows a splash using the app icon (not our large custom bitmap). Icons are displayed smaller by design and can appear to have edges/contours different from our pre‑12 splash, especially on large screens.
  - Our `values-v31/styles.xml` does not declare `android:windowSplashScreenAnimatedIcon` or `android:windowSplashScreenBackground`, so tablets running API 31+ likely use the system default (icon-sized), making the logo look small.
- Density/size effect on large displays (pre‑12 or 12+ fallback paths):
  - The `layer-list` centers `@drawable/splash` without scaling. On very large screens, even the xxxhdpi asset can look proportionally small.
- Possible asset padding:
  - If `splash.png` has transparent padding or a subtle stroke embedded, those edges become noticeable against a pure black background, especially on large panels and certain display modes.

## Goals for the fix
- Tablet‑only adjustment.
- Preserve the existing phone splash exactly as is.
- Avoid risky layout/system UI changes (per prior lessons learned about status bar/fullscreen experiments).

## Targeted, low‑risk fix options (tablet‑only)

1) Minimal-resource overrides using `sw600dp` (recommended)
- Pre‑Android 12 (API < 31):
  - Add `android/app/src/main/res/drawable-sw600dp/launch_background.xml` that mirrors the current file but references a tablet-specific, larger foreground asset, e.g. `@drawable/splash_tablet`.
  - Add `android/app/src/main/res/drawable-sw600dp/splash_tablet.png`.
  - Result: on tablets (smallest width ≥ 600dp), the centered bitmap is larger (because we control the actual pixel size), while phones continue to use the existing assets.
- Android 12+ (API ≥ 31):
  - Add `android/app/src/main/res/values-sw600dp-v31/styles.xml` (and `values-night-sw600dp-v31/styles.xml`) to explicitly set:
    - `android:windowSplashScreenBackground` to black.
    - `android:windowSplashScreenAnimatedIcon` to `@drawable/splash_tablet`.
    - Optionally `android:windowSplashScreenIconBackgroundColor` to black.
  - This forces Android 12+ tablets to use our large tablet image instead of a small icon, without affecting phones.

2) Global Android 12 configuration via plugin, with tablet overrides to preserve phones
- Update `pubspec.yaml` with `flutter_native_splash` `android_12:` block to define `image` and `color`.
- Re-run the plugin to generate base Android 12 resources.
- Then still add `values-sw600dp-v31/` overrides (as in Option 1) if we want tablets to use a different/larger asset than phones.
- This is slightly more moving parts; Option 1 avoids touching phone behavior entirely by relying solely on resource qualifiers.

3) Asset hygiene (do this regardless of option)
- Ensure the tablet splash source (`splash_tablet.png`) is:
  - Trimmed (no transparent padding, no embedded border/stroke).
  - Large enough to look proportionally right on tablets (e.g., 512–720 px on the longest edge, keep aspect ratio, transparent background).
  - Crisp on dark background (pure black pixels near edges can help avoid faint anti-aliased halos).

## Why this is safe and targeted
- Changes are isolated to tablet-specific resource qualifiers (`-sw600dp`) and Android 12+ tablet styles.
- Phones continue to resolve the original resources and styles; no behavior change.
- We avoid any status bar/fullscreen tweaks that previously caused regressions.

## Validation Plan
- Devices/Emulators:
  - Android tablet, API 31+ (Android 12/13).
  - Android tablet, API 29 (pre‑12).
  - Android phone, API 29 and API 33 for regression check.
- Checks:
  - Splash: large, centered logo on tablets; identical behavior on phones.
  - No visible border/outline around the logo (confirm asset is trimmed).
  - Dark mode: verify `values-night-sw600dp-v31` renders correctly (background remains black, logo unchanged).
- Procedure:
  - Clear app data and cold start to ensure splash is shown.
  - Compare before/after screenshots.

## Rollback Plan
- Simply remove the new `-sw600dp` resource folders/files to return to the current behavior.

## Proposed Next Steps (implementation outline, no code yet)
1) Export a borderless, trimmed `splash_tablet.png` at appropriate size.
2) Create `drawable-sw600dp/splash_tablet.png` and `drawable-sw600dp/launch_background.xml` (copy of existing, but pointing to `splash_tablet`).
3) Create `values-sw600dp-v31/styles.xml` (and night variant) that sets `android:windowSplashScreenAnimatedIcon` to `@drawable/splash_tablet` and background to black.
4) Build and test on tablet (API 31+) and phone (API 29/33).
5) If we still want the same larger asset on all Android 12 phones later, add the `android_12:` block to `flutter_native_splash` and regenerate; but we will start with tablet‑only overrides to keep phones unchanged.
