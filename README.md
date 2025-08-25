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

#### Playlist-based Streaming (.m3u)
- Streams for HD1/HD2/HD3 now point to .m3u playlists and are resolved to direct URLs at runtime.
- Resolver lives in `lib/main.dart` → `AudioPlayerHandler._resolvePlaylistUrl()` and uses `dio` + `m3u_nullsafe`.
- Resolved URLs are cached in-memory (keyed by `id|playlistUrl`) to avoid repeated fetches.
- Robust fallbacks: if playlist fetch/parse fails, playback falls back to known-good direct streams.

Configuration
- Set playlist endpoints in `lib/main.dart` → `AudioPlayerHandler.streamUrls`:
  - HD1: https://docs.pacifica.org/kpft/kpft.m3u
  - HD2: https://docs.pacifica.org/kpft/kpft_hd2.m3u
  - HD3: https://docs.pacifica.org/kpft/kpft_hd3.m3u

Troubleshooting
- Fully quit and relaunch the app to clear the in-memory resolution cache if playlists are updated.
- Playlists must ultimately resolve to http/https media URLs. Relative links are supported.
- Malformed links (e.g., duplicated schemes like `https://https://...`) are sanitized by the resolver.

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
- `dio`: HTTP client for playlist fetching
- `m3u_nullsafe`: M3U playlist parser
- `url_launcher`: External link handling
- `cached_network_image`: Image caching and loading

## Getting Started

1. Ensure you have Flutter installed and set up on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app in debug mode


## Postmortem: Offline Connectivity Modal Regression (Android)

This documents the failure so we do not repeat it. iOS remained OK; Android regressed.

### What happened
* __Overlay vs Dialog layering__: An offline overlay with pointer absorption conflicted with a popup dialog, intercepting taps on Android.
* __Play path changed__: While adjusting the modal, edits unintentionally modified `AudioControls` behavior, causing Play taps to be ignored in some states.
* __Unapplied/partial changes__: A duplicate `child` error in `OfflineOverlay` meant local changes were not building cleanly at one point, adding confusion.
* __Lack of isolation__: Changes were not isolated to Android or to the offline UI surface; working paths were touched.

### Root causes
* __Input interception__: `AbsorbPointer` overlay above a `PopupRoute` (dialog) blocked tap events.
* __Coupling__: Offline UI changes were coupled to the Play/Pause control path.
* __Insufficient guardrails__: No strict rule enforced to keep Play/Pause logic unchanged while iterating on offline UX.

### Impact
* Old modal continued to appear on Android at times; buttons felt unresponsive.
* After dismissing, Play stopped responding until state changed again.

### Revert status
* Working tree restored to last known good commit: `feat: lock app orientation` (0e444ce).
* In‑progress work safely stashed as: "Emergency revert WIP before restoring to 'feat: lock app orientation'".

---

## Guardrails (Do NOT break these again)
* __Preserve Play/Pause__: Do not change Play/Pause button position, UI, or onTap logic while working on offline UX.
* __No blocking dialogs for offline__: Prefer a passive, non-dismissible banner/overlay that auto-hides when back online. Do not use `showDialog` for connectivity loss on Android.
* __iOS must remain unchanged__: Android-only fixes must not affect iOS behavior.
* __Small, reviewable changes__: One focused change at a time; run `flutter analyze` and manual tests before commit.
* __Add logs, then code__: Instrument connectivity transitions before altering flows.

---

## Concrete Plan (Single Branch, keeps iOS working)
1. __Baseline__: Keep repo on `0e444ce` (feat: lock app orientation).
2. __Android offline UI__ (no dialogs):
   - Implement a passive message-only overlay for Android that:
     - Shows when `!isOnline`, blocks background taps, contains no buttons.
     - Text: "You're offline. The radio needs internet to play. This alert closes automatically once the internet is restored."
     - Auto-hides when `isOnline`.
   - Do not touch `AudioControls`.
   - Ensure overlay is not rendered over popup routes (if any appear from other features), but avoid introducing new dialogs for connectivity.
3. __Connectivity logging__:
   - Add debug logs in `ConnectivityCubit` on state transitions and `checkNow()` results.
4. __QA pass (Android + iOS)__:
   - Android: Wi‑Fi on → Play works; Airplane on → overlay shows and blocks taps; Airplane off → overlay hides; single Play tap starts playback.
   - iOS: Verify nothing regressed.
5. __Rollback path__:
   - If any regression: `git restore -SW .` to revert uncommitted changes; otherwise reset to `0e444ce`.

---

## Files allowed to change for the Android offline fix
* `lib/presentation/widgets/offline_overlay.dart` — implement passive, message-only overlay.
* `lib/main.dart` — at most, adjust the global builder to ensure overlay layering does not cover popup routes. Do not modify `AudioControls`.
* `lib/presentation/bloc/connectivity_cubit.dart` — add logs only; no behavioral coupling to Play control.

---

## Manual Test Matrix
1. __Android__
   - Launch online → tap Play → audio starts.
   - Turn Airplane Mode ON → overlay appears; controls blocked.
   - Turn Airplane Mode OFF → overlay disappears automatically; tap Play once → audio starts.
   - Rotate and background/foreground app → state remains consistent.
2. __iOS__
   - Repeat above; ensure no changes in UI/behavior.

---

## Known Working Fix: Prevent Startup Modal Popup and Allow Auto-Close

This section captures the first fix that worked today and should be reapplied exactly when we resume.

### Goals
* __No modal at app startup__: Avoid a jarring popup on cold launch when the device is offline.
* __Auto-close when back online__: If a modal is shown via explicit user action, it must close itself when connectivity returns.
* __No interference with Play controls__: Do not change Play/Pause logic.

### Implementation Summary
* __Connectivity first-run suppression__ (`lib/presentation/bloc/connectivity_cubit.dart`):
  - Keep a `firstRun` flag. Do not trigger the modal/overlay during the initial connectivity probe on cold start.
  - Start showing offline UI only on subsequent connectivity changes (or after a small debounce on Android).
* __Overlay layering guard__ (`lib/main.dart`):
  - Only insert `OfflineOverlay` when the current top route is not a `PopupRoute` (dialog). This prevents the overlay from sitting above a dialog and stealing taps.
  - Keep overlay message-only (no buttons) and auto-hide when `isOnline`.
* __Modal behavior__ (`lib/presentation/widgets/offline_modal.dart`):
  - If a modal is ever shown (triggered by an explicit user action), set `barrierDismissible: false` and subscribe to connectivity.
  - When `isOnline` becomes true, call `Navigator.of(context, rootNavigator: true).maybePop()` to auto-close.
  - Do not modify Play/Pause button code.

### Why this works
* Prevents the initial startup popup.
* Ensures any user-invoked modal cleanly auto-closes on reconnection.
* Overlay never blocks dialog taps because it is not rendered over popup routes.

### Reapply Checklist
1. Add/verify `firstRun` suppression in `ConnectivityCubit`.
2. Add overlay route check in `main.dart` before building `OfflineOverlay`.
3. Keep modal auto-close on connectivity and `barrierDismissible: false`.
4. Leave Play/Pause logic untouched.
