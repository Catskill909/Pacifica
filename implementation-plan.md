# Implementation Plan for KPFT Multi-Stream Radio App

## 1. Architecture Changes

### 1.1 Audio Service Enhancement
- Modify AudioPlayerHandler to support multiple streams
- Add stream management for HD1, HD2, and HD3
- Implement proper cleanup between stream transitions
- Add stream reset functionality for tab switches

### 1.2 State Management
- Create a StreamController for active tab state
- Implement audio session management per tab
- Handle WebView state preservation
- Manage media notification updates

## 2. UI Implementation

### 2.1 Tab Navigation
```dart
CustomBottomNavigationBar {
  - Black background (Colors.black)
  - Vertical separators between tabs
  - Text colors: 
    * Selected: Colors.white
    * Unselected: Colors.grey[400]
  - Fixed tab width distribution
  - Custom tab indicator
}
```

### 2.2 Tab Configuration
```dart
final tabConfig = [
  TabItem(
    label: "HD1",
    webViewUrl: "https://starkey.digital/app/",
    audioStream: "https://streams.pacifica.org:9000/live_64",
  ),
  TabItem(
    label: "HD2",
    webViewUrl: "https://starkey.digital/app2/",
    audioStream: "https://streams.pacifica.org:9000/HD3_128",
  ),
  TabItem(
    label: "HD3",
    webViewUrl: "https://starkey.digital/app3/",
    audioStream: "https://streams.pacifica.org:9000/classic_country",
  ),
  TabItem(
    label: "DONATE",
    externalUrl: "https://kpft.org/support-kpft/",
    isDonateTab: true,
  ),
]
```

## 3. Core Features Implementation

### 3.1 Audio Stream Management
```dart
class AudioStreamManager {
  - Stream initialization
  - Cleanup on tab switch
  - Media controls sync
  - Notification updates
}
```

### 3.2 WebView Controller
```dart
class CustomWebViewController {
  - State preservation
  - Load management
  - Error handling
  - External URL handling
}
```

### 3.3 Tab Controller
```dart
class TabStateController {
  - Active tab tracking
  - Stream state management
  - WebView state preservation
  - Donate tab special handling
}
```

## 4. Implementation Steps

1. **Setup Enhanced Audio Service**
   - Modify AudioPlayerHandler for multiple streams
   - Implement stream cleanup
   - Add media control synchronization

2. **Create Custom Navigation**
   - Implement bottom tab bar with separators
   - Add tab styling and indicators
   - Handle tab selection states

3. **Implement Tab Content**
   - Create tab-specific WebView containers
   - Setup audio stream connections
   - Implement donate tab external linking

4. **State Management**
   - Setup stream state tracking
   - Implement WebView state preservation
   - Add tab state management

5. **Media Controls**
   - Update notification tray controls
   - Sync lock screen media information
   - Handle audio focus changes

6. **Testing & Optimization**
   - Test stream transitions
   - Verify state preservation
   - Check memory management
   - Validate notification controls

## 5. Technical Considerations

### 5.1 Memory Management
- Implement proper disposal of audio streams
- Handle WebView cleanup
- Manage state controllers lifecycle

### 5.2 Error Handling
- Network connectivity issues
- Stream initialization failures
- WebView loading errors

### 5.3 Performance
- Lazy loading of inactive tabs
- Efficient stream switching
- Minimal memory footprint

## 6. Future Enhancements

- Stream quality selection
- Offline mode
- Background audio persistence
- Custom notification layouts