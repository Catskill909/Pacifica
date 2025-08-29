# KPFT Audio Transport Controls Analysis & Fix Plan

## Problem Statement
The notification tray audio transport controls are not working correctly **on Android**. The play/pause buttons sometimes don't work, and using the notification controls causes the app to get "out of whack" with state synchronization issues.

**IMPORTANT**: This fix is **Android-specific only**. iOS has been released with no issues and must remain unchanged.

## Current Implementation Analysis

### AudioPlayerHandler Structure
The app uses `audio_service` package with a custom `AudioPlayerHandler` that extends `BaseAudioHandler`. Key components:

1. **Core Audio Player**: Uses `just_audio` package (`AudioPlayer` instance)
2. **State Broadcasting**: `_broadcastState()` method syncs player state to notification
3. **Media Controls**: Dynamic controls based on playing state
4. **Stream Management**: M3U playlist resolution with fallback URLs

### Current State Management Flow

```
AudioPlayer (just_audio) 
    ↓ playbackEventStream
_broadcastState() 
    ↓ playbackState.add()
Notification Tray Controls
    ↓ MediaControl actions
AudioPlayerHandler methods (play/pause/stop)
    ↓ back to AudioPlayer
```

### Identified Issues

#### 1. **State Synchronization Problems**
- **Root Cause**: The `setMediaItem()` method has inconsistent state handling
- **Line 279-291**: When switching streams, the method:
  1. Stops current player (`await _player.stop()`)
  2. Sets new URL (`await _player.setUrl(resolved)`)
  3. Broadcasts state (`_broadcastState(_player.playbackEvent)`)
  4. **PROBLEM**: Conditionally restarts playback (`if (_player.playing)`)

The issue is that after `stop()`, `_player.playing` is `false`, so the conditional restart never happens, but the notification may still show "pause" state.

#### 2. **Notification Control State Desync**
- **Line 205**: Controls are set based on `_player.playing` state
- **Problem**: When stream switching occurs, there's a timing gap where:
  1. Player is stopped (playing = false)
  2. State is broadcast (shows play button)
  3. New stream is loaded
  4. But playback doesn't auto-resume
  5. User sees play button but expects pause button

#### 3. **Missing Override Methods**
The `AudioPlayerHandler` doesn't override critical `BaseAudioHandler` methods:
- No `@override` for `play()`, `pause()`, `stop()` - these should be explicitly marked
- Missing `seek()` method override
- No proper error handling in notification callbacks

#### 4. **Inconsistent Reset Behavior**
- **App UI**: Play/pause button resets audio to initial state (as intended)
- **Notification**: Should behave the same but doesn't due to state management issues
- **Line 500-514**: App UI has proper connectivity checks and state management
- **Notification**: Bypasses these checks and directly calls handler methods

## Recommended Solution (Android-Only)

### Phase 1: Platform-Specific State Management

#### 1.1 Enhanced AudioPlayerHandler with Platform Detection
```dart
import 'package:flutter/foundation.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  // Android-only state tracking
  bool _isStreamSwitching = false;
  bool _shouldResumeAfterSwitch = false;
  
  @override
  Future<void> pause() async {
    // Android-specific: Reset to initial state (matches app UI)
    // iOS: Keep standard pause behavior (released functionality)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await resetToInitial();
    } else {
      await _player.pause();
      _broadcastState(_player.playbackEvent);
    }
  }
}
```

#### 1.2 Platform-Specific setMediaItem Method
```dart
Future<void> setMediaItem(MediaItem mediaItem) async {
  final playlistUrl = streamUrls[mediaItem.id];
  if (playlistUrl != null) {
    // Android-specific: Enhanced state management
    // iOS: Simplified approach to maintain released functionality
    if (defaultTargetPlatform == TargetPlatform.android) {
      _isStreamSwitching = true;
      _shouldResumeAfterSwitch = _player.playing;
    }
    
    await _player.stop();
    final resolved = await _resolvePlaylistUrl(mediaItem.id, playlistUrl);
    await _player.setUrl(resolved);
    _mediaItem = mediaItem.copyWith(duration: const Duration(hours: 24));
    
    _broadcastState(_player.playbackEvent);
    
    // Android-specific: Resume if was playing before switch
    // iOS: Let user manually restart
    if (defaultTargetPlatform == TargetPlatform.android && _shouldResumeAfterSwitch) {
      await _player.play();
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      _isStreamSwitching = false;
    }
  }
}
```

#### 1.3 Platform-Aware State Broadcasting
```dart
void _broadcastState(PlaybackEvent event) {
  final playing = _player.playing;
  final processingState = _mapProcessingState(_player.processingState);
  
  // Android-specific: Show play button during stream switching
  // iOS: Keep standard behavior
  final controls = (defaultTargetPlatform == TargetPlatform.android && _isStreamSwitching)
    ? [MediaControl.play]
    : [if (playing) MediaControl.pause else MediaControl.play];
  
  playbackState.add(playbackState.value.copyWith(
    controls: controls,
    androidCompactActionIndices: [0],
    processingState: processingState,
    playing: playing,
    updatePosition: _player.position,
    bufferedPosition: _player.bufferedPosition,
    speed: _player.speed,
    queueIndex: event.currentIndex,
  ));
  mediaItem.add(_mediaItem);
}
```

### Phase 3: Add Connectivity Awareness

#### 3.1 Connectivity Integration
```dart
class AudioPlayerHandler extends BaseAudioHandler {
  ConnectivityService? _connectivityService;
  
  void setConnectivityService(ConnectivityService service) {
    _connectivityService = service;
  }
  
  @override
  Future<void> play() async {
    // Check connectivity before playing
    if (_connectivityService != null) {
      final isOnline = await _connectivityService.checkConnectivity();
      if (!isOnline) {
        // Don't start playback if offline
        return;
      }
    }
    
    // Rest of play logic...
  }
}
```

## Implementation Priority

### High Priority (Fix Immediately)
1. **Fix `setMediaItem()` state management** - prevents notification desync
2. **Add proper state broadcasting** - ensures UI consistency
3. **Implement reset behavior in notification** - matches app UI behavior

### Medium Priority
1. **Add connectivity checks to notification controls**
2. **Enhance error handling in audio service**
3. **Add proper method overrides with @override annotations**

### Low Priority
1. **Add seek functionality for notification**
2. **Implement skip next/previous for multiple streams**

## Testing Strategy

### Manual Testing Checklist
- [ ] Start audio from app - notification shows correct state
- [ ] Pause from notification - audio resets (matches app behavior)
- [ ] Play from notification - audio starts correctly
- [ ] Switch streams - notification updates correctly
- [ ] Test offline scenarios - notification handles gracefully
- [ ] Test rapid play/pause cycles - no state desync

### Edge Cases to Test
- [ ] Stream switching while audio is playing
- [ ] Network loss during playback
- [ ] App backgrounded/foregrounded during playback
- [ ] Multiple rapid notification button presses
- [ ] Device rotation during playback

## Expected Outcome

After implementing these fixes:
1. **Notification controls will behave identically to app UI controls**
2. **Play/pause state will remain synchronized between app and notification**
3. **Stream switching will not cause state desynchronization**
4. **Pause action will reset audio to initial state (matching app behavior)**
5. **Connectivity issues will be handled consistently across all interfaces**

The key insight is that the notification controls should mirror the app's "reset on pause" behavior rather than implementing traditional pause/resume functionality.
