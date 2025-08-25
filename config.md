# Configuration Plan for Reskinning the App

This file outlines the elements that can be configured in a central configuration file to facilitate easy reskinning of the app.

## 1. Images
- **Logo**: 
  - Path: `assets/kpft.png`
- **Background Images**:
  - Example: `assets/background.png` (Add paths for any additional background images)
- **Art URI for Audio**:
  - URL: `https://starkey.digital/app/kpft2.png`

## 2. Titles and Headers
- **App Title**: 
  - Value: `"KPFT 90.1 FM"`
- **News Title**: 
  - Value: `'KPFT News'`
- **Post Titles**: 
  - Dynamic based on WordPress API response (e.g., `snapshot.data![index].title`)

## 3. Audio Stream Configuration
- **Playlist Endpoints (resolved at runtime)**:
  - Configured in `lib/main.dart` → `AudioPlayerHandler.streamUrls`
  - HD1: `https://docs.pacifica.org/kpft/kpft.m3u`
  - HD2: `https://docs.pacifica.org/kpft/kpft_hd2.m3u`
  - HD3: `https://docs.pacifica.org/kpft/kpft_hd3.m3u`

- **Fallback Direct Streams (for resilience)**:
  - HD1: `https://streams.pacifica.org:9000/live_64`
  - HD2: `https://streams.pacifica.org:9000/HD3_128`
  - HD3: `https://streams.pacifica.org:9000/classic_country`
- **Audio Metadata**:
  - Album: `"Live on the air"`
  - Artist: `"Houston's Community Station"`
  - Duration: `5739820 milliseconds` (or dynamic if needed)

## 4. WordPress API Configuration
- **WordPress API Endpoint**:
  - URL: `https://kpft.org/wp-json/wp/v2/posts?per_page=20`
  
## 5. Social Media Links
- **Twitter**: 
  - URL: `https://twitter.com/KpftHouston`
- **Facebook**: 
  - URL: `https://www.facebook.com/kpfthouston/`
- **Instagram**: 
  - URL: `https://www.instagram.com/kpfthouston/?hl=en`
- **YouTube**: 
  - URL: `https://www.youtube.com/channel/UCxf2097DYBA96ffsMwoV4hw`

## 6. Styling
- **Primary Color**: 
  - Value: `#B81717` (Red)
- **Secondary Color**: 
  - Value: `#FFFFFF` (White)
- **Font Family**: 
  - Value: `Oswald` (or any other font family used in the app)
- **Font Size**: 
  - Default: `16` (adjustable based on specific UI elements)

## 7. Additional Configuration
- Any other configurable elements can be added here as needed.
