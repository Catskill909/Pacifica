# Android Duplicate Lock Screen Controls — Root Cause, Fix, and Validation

Date: 2025-08-29
Owner: Engineering
Scope: Android lock screen media controls for KPFT app

---

## Symptoms
- After pressing Pause from the Android lock screen, two media control surfaces appear:
  - The standard system lock screen media controls at the top.
  - The app’s media notification controls below (both control the same playback).
- Generic system text is no longer shown (resolved earlier).

## Root Cause
- The duplicate appearance occurs when the MediaSession/notification remains visible while the lock screen’s media panel is also shown.
- On certain Android lock screens (Samsung/older Android variants), the media notification can remain visible together with the lock screen media panel when the session is not fully terminated or when controls continue to be published.
- Our handler previously left controls/metadata present during/after pause, which could keep the notification surface alive alongside the lock screen panel.

## Final Fix (Implemented)
All changes in `lib/main.dart`.

1) AudioService configuration
- In `main()` → `AudioService.init(...)`
  - `androidNotificationChannelId: 'com.example.myapp.channel.audio'` (restored to avoid dual MediaSession conflicts)
  - `androidStopForegroundOnPause: true` (dismiss notification on pause/stop)

2) Broadcast policy when idle
- In `AudioPlayerHandler._broadcastState()`:
  - When `processingState == AudioProcessingState.idle`:
    - Publish no controls: `controls: []`
    - Publish no compact actions: `androidCompactActionIndices: []`
    - Send `mediaItem: null` to clear the lock screen and notification.

3) Pause/Stop semantics
- In `AudioPlayerHandler.pause()`:
  - On Android, map pause to `stop()` to fully clear the session & notification and avoid any residual surfaces.
  - On iOS, keep a real pause.
- In `AudioPlayerHandler.stop()`:
  - `await _player.stop();`
  - Immediately call `_broadcastState(...)` to push the final idle state (no controls + null media item).
  - `await super.stop();` to terminate the service/MediaSession.

4) Minor hygiene
- Ensure handler is strongly typed as `AudioPlayerHandler` (no unnecessary casts).

## Code locations
- `lib/main.dart`
  - `main()` → `AudioService.init(...)`
  - `AudioPlayerHandler._broadcastState()`
  - `AudioPlayerHandler.pause()`
  - `AudioPlayerHandler.stop()`

## Why this works
- Setting `mediaItem` to `null` and publishing empty controls on idle instructs Android to remove media surfaces.
- Mapping pause→stop on Android terminates the foreground notification and session cleanly, avoiding a state where both the lock screen panel and the notification are visible simultaneously.
- `androidStopForegroundOnPause: true` ensures the notification is dismissed when pausing/stopping.

## Validation Steps
1) Fresh install (optional but recommended)
- Uninstall app to clear any old notification channels.
- Reinstall and run on a device.

2) Playback
- Start playback (HD1/HD2/HD3). Confirm lock screen shows correct controls and art.

3) Pause from lock screen
- Press Pause on lock screen.
- Expected: All media controls disappear (no duplicate players, no generic text).

4) Resume
- Unlock and tap Play in the app. Controls reappear normally on lock screen.

5) Stream switch
- Switch tabs HD1↔HD2↔HD3. Playback does not auto-start; one Play tap starts playback.

6) Optional verification (advanced)
- `adb shell dumpsys media_session | grep -A 8 -i kpft` and ensure only one active MediaSession appears while playing, and none when stopped.

## Notes
- Some OEM lock screens can display both the system media panel and the notification shade while on the lock screen. With the above policy (idle → no controls + null media + stop service), the notification and panel should both dismiss after Pause/Stop, preventing the duplicate appearance.

## Rollback
- If any regression appears, revert only the pause mapping and idle broadcast changes, but keep `androidStopForegroundOnPause: true` and the restored channel id.

## Status
- Implemented and analyzed.
- Awaiting user device verification screenshots after pressing Pause from the lock screen.
