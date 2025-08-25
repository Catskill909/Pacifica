# KPFT Audio Streaming Audit (Icecast)

Date: 2025-08-18
Owner: Engineering
Scope: Audio stack only (no UI changes, no code diffs). Findings reference current project files and symbols.

## Executive Summary
- The app uses `just_audio` + `audio_service` with a custom `AudioPlayerHandler` for background playback and notifications. Core path is sound and production-proven.
- Platform entitlements are mostly correct (Android foreground service, iOS background audio). Some security/privacy flags need refinement.
- The implementation does not yet configure an audio session (`audio_session`) or audio focus/ducking, which is key for reliability, interruptions, and silent-mode behavior.
- Icecast best practices (ICY metadata capture, reconnect/backoff strategy, stream-specific headers) are not implemented yet.
- Dependencies include desktop backends (`just_audio_mpv`, `just_audio_windows`) that may be unnecessary for mobile release builds.

- Playlist-based streaming is now implemented: `.m3u` playlists for HD1/HD2/HD3 are resolved at runtime with URL sanitization (duplicate scheme fix), validation, caching per `id|playlistUrl`, and fallback to direct streams.

Bottom line: With a few targeted improvements (audio session config, focus/ducking, metadata, reconnection, minor Android/iOS hygiene), we can reach a robust, modern radio experience.

---

## Inventory

- Packages (pubspec.yaml)
  - just_audio: ^0.9.35
  - audio_service: ^0.18.12
  - audio_session: ^0.1.14
  - rxdart: ^0.28.0 (not directly used for audio path currently)
  - just_audio_mpv: ^0.1.6 (Linux backend)
  - just_audio_windows: ^0.2.0 (Windows backend)
  - connectivity_plus: ^6.1.3 (used for online/offline UX)
  - url_launcher: ^6.2.1 (for external links)

- Key code paths
  - lib/main.dart
    - `AudioPlayerHandler extends BaseAudioHandler`
      - `play()`, `pause()`, `stop()`
      - `prepareCurrent()`
      - `setMediaItem(MediaItem)`
      - `streamUrls` for HD1/HD2/HD3
      - `_broadcastState(PlaybackEvent)`
    - `AudioService.init(...)` in `main()`
    - UI wiring via `AudioControls` and `StreamBottomNavigation`

- Platform configuration
  - Android: `android/app/src/main/AndroidManifest.xml`
    - INTERNET, WAKE_LOCK, FOREGROUND_SERVICE permissions
    - `AudioServiceActivity`, `AudioService` service, `MediaButtonReceiver`
    - `android:usesCleartextTraffic="true"` (not needed for HTTPS streams)
  - iOS: `ios/Runner/Info.plist`
    - `UIBackgroundModes` includes `audio`
    - `NSMicrophoneUsageDescription` present (microphone is NOT used)

---

## Architecture Review

- Playback engine: `just_audio` (ExoPlayer on Android, AVPlayer on iOS) initialized inside `AudioPlayerHandler`.
- Background: `audio_service` 0.18 handler-based architecture with notification channel.
- Media metadata: `MediaItem` updates are posted; artUri present. No dynamic metadata updates from stream.
- Lifecycle: Connectivity changes handled to stop or pre-prepare on regain. No reconnection/backoff loop in the player itself.
- Session/Focus: No audio session config, focus/ducking, or interruption handling via `audio_session`.

---

## Strengths

- Stable, widely used stack (just_audio + audio_service).
- Background playback and media notification set up on Android.
- Clear separation of handler logic and UI.
- Stream switching is explicit and simple.

---

## Gaps and Risks

- Session/Focus (High)
  - `audio_session` is declared but not used. Without configuring `AVAudioSession` (iOS) and audio focus (Android):
    - Playback may stop or behave unpredictably during interruptions (calls, Siri, alarms) or in silent mode (iOS).
    - Ducking/unducking may not behave as expected.

- Interruptions & Route Changes (High)
  - No listeners for audio interruptions (phone call) or route changes (headphones unplugged). On Android, a “becoming noisy” event typically pauses playback.

- Icecast ICY Metadata (Medium)
  - We are not requesting or processing ICY metadata (current song/artist) from the stream. `just_audio` exposes `IcyMetadata` via playback events. The UX and lock screen could reflect live track changes.

- Reconnect and Resilience (Medium)
  - Current approach stops on offline and prepares on regain via `ConnectivityCubit`. No automatic retry/backoff for transient errors (server hiccups), or internal connection retry policy.

- Android Manifest Hygiene (Medium)
  - `android:usesCleartextTraffic="true"` enabled even though streams are HTTPS. This weakens network security posture.
  - Notification channel id is `com.example.myapp.channel.audio` (mismatch with package `com.pacifica.app.pacifica2`).

- iOS Privacy Hygiene (Medium)
  - `NSMicrophoneUsageDescription` present though we do not record. This can trigger App Store review questions and confuse users.

- Desktop Backends in Mobile Builds (Low)
  - `just_audio_mpv` and `just_audio_windows` inflate dependency graph. If mobile-only release, consider moving them behind platform conditions or dev-only to reduce build complexity.

- Buffering & Latency Tuning (Low)
  - No explicit buffer/LoadControl tuning. Defaults are fine for most users, but poor networks might benefit from slightly larger initial buffer and better retry policy.

---

## Icecast-Specific Best Practices

- Request ICY metadata and surface it:
  - Ensure the player requests ICY metadata and subscribe to metadata updates to display current track in the UI and push to lock screen/notification metadata.

- Robust reconnection:
  - Implement exponential backoff retry for dropped streams (e.g., 0.5s, 1s, 2s, 4s ... capped), with user feedback if a long outage persists.

- Stream health telemetry:
  - Log playback errors, stalls, and retry attempts with tags (station id, timestamp) to analyze station reliability.

- TLS, redirects, and CORS:
  - Use HTTPS-only streams. Confirm follow-redirect behavior and TLS validity for the Icecast endpoints.

---

## Platform Audit Details

- Android (`android/app/src/main/AndroidManifest.xml`)
  - Foreground service and media button receiver present. Good.
  - Channel id/name provided in `AudioService.init` — recommend aligning id with appId and adding a description.
  - Consider enabling audio focus and ducking via `audio_session` and verifying media button events mapping through `audio_service`.
  - Remove `usesCleartextTraffic` unless there are known HTTP-only endpoints.

- iOS (`ios/Runner/Info.plist`)
  - `UIBackgroundModes` includes `audio`. Good.
  - Remove `NSMicrophoneUsageDescription` if the mic is never used.
  - Configure `AVAudioSession` to `playback`, activate on start, handle interruptions and route changes (via `audio_session`).

---

## Handler Review (`lib/main.dart`)

- `AudioPlayerHandler`
  - Uses `setUrl()` when idle/completed; updates `MediaItem`; maps `ProcessingState`.
  - Recommendations
    - Add audio session configuration on handler init (category: playback; focus/ducking).
    - Subscribe to and handle interruptions/route changes (pause on incoming call; pause on headphones unplug; resume policy).
    - Add retry/backoff for transient `setUrl`/play failures.
    - Attach ICY metadata updates to now playing info and notification metadata.
    - Ensure `stop()` updates state and releases focus; confirm service stop behavior if desired when paused for long.

- `play()` / `setMediaItem()`
  - Ensure a consistent prepare-before-play flow; current design is adequate but consider eager preparation during tab switch if UX calls for it.
  - During tab switch, retain play/pause state (already supported). Good.

---

## Performance & UX

- Start-up latency
  - Pre-prepare current stream after app regains connectivity (already done). Consider pre-prepare at app start after handler init.

- Buffering
  - Defaults are ok; if users report stutter on poor networks, consider slightly higher initial buffer and retry policy.

- Background & lock screen
  - Notification shows play/pause. Verify lock screen shows station art and updates track metadata from ICY.

- Battery
  - Foreground service will keep CPU awake during playback. Ensure the app stops service or releases focus when stopped to avoid excess battery drain.

---

## Security & Privacy

- Network security
  - Prefer HTTPS-only streams. Remove cleartext traffic.

- Permissions
  - Remove microphone permission description to avoid implying voice capture.

- Data collection
  - If adding telemetry, document what is collected (only playback events), and surface in privacy policy.

---

## Version & Compatibility

- Validate current versions with `flutter pub outdated` prior to release.
  - just_audio 0.9.x and audio_service 0.18.x are compatible.
  - Recheck change logs for any breaking changes regarding ICY metadata handling or Android 14 foreground service policies.

---

## Prioritized Recommendations (No Code Included Here)

1) Audio Session & Focus (High)
- Configure `audio_session` on app/handler init: playback category, ducking, interruptions, route changes.

2) ICY Metadata (High)
- Enable ICY metadata retrieval and propagate to UI/notification/lock screen.

3) Reconnect Strategy (Medium)
- Implement exponential backoff retry on network errors/timeouts while maintaining Play/Pause semantics.

4) Android/iOS Hygiene (Medium)
- Android: align notification channel id with package; remove `usesCleartextTraffic` if not needed.
- iOS: remove microphone usage description; verify background playback in silent mode and with screen locked.

5) Dependency Slimming (Low)
- Move desktop audio backends behind platform conditions or dev-only if mobile release is the focus.

6) Telemetry (Low)
- Add lightweight logging of playback failures, stalls, and retries for ops visibility.

---

## Validation Plan

- Functional
  - Start/Stop/Play/Pause across all three streams (HD1/HD2/HD3) with tab switching.
  - Background playback with screen off and with app in background.
  - Headphones unplug: auto-pause (Android), confirm behavior on iOS.
  - Incoming call/Siri/alarm: interruption handling and resume policy.
  - Device mute/silent switch (iOS): audio plays in `playback` category.

- Network
  - Toggle Wi‑Fi/cellular; simulate brief drop and confirm reconnect/backoff.
  - Verify no audio under airplane mode; ensure clean error surfaces and recovery after network returns.

- Metadata
  - Confirm ICY metadata appears in app UI, Android notification, and iOS lock screen.

- Release checks
  - Android 13/14: media notification controls; foreground service policy compliance.
  - iOS: App Store privacy review (no mic permission), background audio entitlement active.

---

## Release Readiness Checklist

- [ ] Audio session configured (focus/ducking/interruptions/route changes)
- [ ] ICY metadata captured and displayed
- [ ] Reconnect/backoff implemented for transient errors
- [ ] Android: channel id aligned; cleartext disabled (unless required)
- [ ] iOS: microphone description removed; playback in silent mode confirmed
- [ ] Battery: service/focus released when stopped
- [ ] Telemetry for playback failures
- [ ] Manual test pass across HD1/HD2/HD3 in foreground, background, and with network transitions

---

## References

- `lib/main.dart` — `AudioPlayerHandler`, `AudioService.init`, `AudioControls`
- `android/app/src/main/AndroidManifest.xml` — audio service & receiver; network flags
- `ios/Runner/Info.plist` — background audio, microphone description
- Packages: `just_audio`, `audio_service`, `audio_session`
