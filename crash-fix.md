# Audio Player Crash Fixes

## Crash #1 (Fixed and Tested)
**Issue:** Resources not being cleaned up during app termination
**Fix Implementation:**
```dart
Future<void> dispose() async {
  await _eventSubscription.cancel();
  await _player.dispose();
}
```
**Status:** Fixed and tested successfully

## Crash #2 (Needs Implementation)
**Issue:** App crashes while broadcasting events during disposal
**Stack Trace:**
```
Exception Type: EXC_CRASH (SIGABRT)
Key Stack Trace:
6   just_audio    -[AudioPlayer broadcastPlaybackEvent] + 388
7   just_audio    -[AudioPlayer dispose] + 56
8   just_audio    -[JustAudioPlugin dealloc] + 164
```
**Root Cause:** Race condition where the player tries to send events through Flutter channels while being disposed

**Proposed Fix:**
```dart
Future<void> dispose() async {
  // Stop playback first to prevent event broadcasting during disposal
  await _player.stop();  // <-- New line to prevent event broadcasting
  await _eventSubscription.cancel();
  await _player.dispose();
}
```
**Status:** Not yet implemented or tested

## Testing Instructions
1. For Crash #2 Fix:
   - Build and run in release mode
   - Play any audio content
   - While audio is playing, force-close the app
   - App should close gracefully without crash
   - Repeat several times to ensure reliability

2. Regression Testing:
   - Verify audio playback works normally
   - Verify stopping/starting audio works
   - Verify normal app closure works
   - Ensure fix #1 remains functional

## Next Steps
1. Implement the fix for Crash #2
2. Test locally in release mode
3. If successful, push to repository
4. Deploy new TestFlight build for user testing
