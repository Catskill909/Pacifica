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
- `url_launcher`: External link handling
- `cached_network_image`: Image caching and loading

## Getting Started

1. Ensure you have Flutter installed and set up on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app in debug mode