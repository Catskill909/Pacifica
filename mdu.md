# KPFT Audio Stream URL Migration to .m3u — Ground Plan

## Goals
- Replace direct stream URLs with .m3u playlist URLs for HD1/HD2/HD3.
- Resolve .m3u to a direct playable media URL at runtime (works on iOS and Android).
- Preserve all existing UI and audio behaviors (play/pause, background playback, tab switching, donate tab).

## Inputs (new playlist URLs)
- HD1: https://docs.pacifica.org/kpft/kpft.m3u
- HD2: https://docs.pacifica.org/kpft/kpft_hd2.m3u
- HD3: https://docs.pacifica.org/kpft/kpft_hd3.m3u

## Current touch points (code inventory)
- `lib/main.dart`
  - `AudioPlayerHandler.streamUrls` — currently maps HD1/HD2/HD3 to direct streams.
  - `AudioPlayerHandler.play()` — calls `_player.setUrl(streamUrl)`
  - `AudioPlayerHandler.prepareCurrent()` — calls `_player.setUrl(streamUrl)`
  - `AudioPlayerHandler.setMediaItem()` — calls `_player.setUrl(streamUrl)` then optionally resumes playback.
- WebView URLs were already updated; no further changes there.

## Package decision
- Choose: `m3u_nullsafe`
  - Reason: actively referenced on pub.dev, null-safe, simple API, widely used for basic M3U parsing.
  - Alternative (`m3u_parser_nullsafe`) shows lower trust signals and unverified uploader.

## Implementation strategy
1. Dependency
   - Add to `pubspec.yaml` (dependencies): `m3u_nullsafe: ^2.x` (latest stable).
   - Use existing `dio` (already in project) for HTTP GET of playlist text.

2. Playlist resolver helper (inside `AudioPlayerHandler`)
   - `Future<String> _resolvePlaylistUrl(String url)`
     - If `url` ends with `.m3u` (case-insensitive):
       - Fetch with Dio (short timeouts, e.g., 3s connect/3s receive).
       - Parse text with `M3uParser.parse(playlistText)`.
       - Pick the first valid entry URL (prefer https). Resolve relative URLs against playlist base URL if necessary.
       - Return the resolved direct URL.
     - Else return `url` unchanged.
     - On any error, log and return the original `url` as fallback (do not break playback).
   - Add a small in-memory cache: `Map<String, String> _resolvedCache` keyed by `id|playlistUrl`.
     - This ensures changes to playlist URLs bypass stale cache entries. Cache clears on app restart.

3. Wire resolver into playback
   - In `prepareCurrent()`, `play()`, and `setMediaItem()`:
     - Look up the (playlist) URL from `streamUrls[id]`.
     - Resolve via `_resolvePlaylistUrl()` (use cache first).
     - Call `_player.setUrl(resolvedUrl)`.
   - Preserve current logic for stopping/playing; do not alter UI or state transitions.

4. Replace stream URL map values
   - `AudioPlayerHandler.streamUrls` becomes:
     - `HD1: https://docs.pacifica.org/kpft/kpft.m3u`
     - `HD2: https://docs.pacifica.org/kpft/kpft_hd2.m3u`
     - `HD3: https://docs.pacifica.org/kpft/kpft_hd3.m3u`

5. Error handling and resilience
   - Timeouts and exceptions should NOT crash or block user; fallback to original URL.
   - Log failures for diagnostics.
   - Maintain existing connectivity handling (no changes to `ConnectivityService` or overlays).

6. Regression scope (must remain unchanged)
   - Play/Pause button position and behavior.
   - Top section and images.
   - WebView and Donate tab (external browser).
   - Only audio stream resolution is added under the hood.

## Test plan
- Switch tabs HD1/HD2/HD3 — verify audio starts/stops correctly and resumes if playing before.
- Background playback on iOS and Android.
- Offline → online cycle: ensure `prepareCurrent()` still works with resolver.
- Validate that `.m3u` content variations (comments, multiple entries) still resolve first playable URL.
- Rollback safety: if any issues, we can revert `streamUrls` to previous direct URLs and remove resolver (no UI impact).

## Next steps
1. Add `m3u_nullsafe` to `pubspec.yaml` and run `flutter pub get`.
2. Implement `_resolvePlaylistUrl` + caching in `AudioPlayerHandler`.
3. Update `streamUrls` to playlist URLs.
4. Manual tests on both platforms.

## Implementation notes (as built)
- Resolver implemented in `lib/main.dart` → `AudioPlayerHandler._resolvePlaylistUrl()` using `dio` + `m3u_nullsafe`.
- Cache key is `id|playlistUrl` to avoid collisions and stale resolutions.
- Relative links are resolved against the playlist base URL.
- Fallback to known-good direct streams if fetch/parse/validation fails.

### Hardening
- Sanitize duplicated schemes (e.g., `https://https://...`) by collapsing to a single scheme.
- Validate final URL: must be `http/https` and have a non-empty host.
- On any exception, fall back to direct URLs to preserve playback.

### Troubleshooting
- If playlist contents change but are served at the same URL, fully quit and relaunch the app to refresh the cache.
- Ensure playlist lines are valid media URLs or resolvable relative paths.

### Verification checklist
- Switch HD1/HD2/HD3 and confirm playback starts quickly.
- Background playback continues after minimizing/locking.
- Donate tab still opens in external browser.
