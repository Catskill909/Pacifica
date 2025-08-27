# WebView Scrim Overlay

## Overview
The app uses a WebView-only scrim overlay to improve offline/error UX without blocking the rest of the UI:
- Covers only the WebView region.
- Shows a spinner while loading.
- Shows a blocking message with a Reload button on offline/error.
- Suppressed during startup grace/checking to avoid flicker.

## Files
- [lib/presentation/widgets/webview_container.dart](cci:7://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/widgets/webview_container.dart:0:0-0:0)
  - Wraps [CustomWebView](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:5:0-12:1) and wires the scrim with connectivity + WebView state.
- [lib/presentation/widgets/webview_scrim.dart](cci:7://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/widgets/webview_scrim.dart:0:0-0:0)
  - The overlay UI for loading/offline/error states.
- [lib/webview.dart](cci:7://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:0:0-0:0)
  - [CustomWebView](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:5:0-12:1) exposes:
    - `ValueListenable<bool> isLoadingListenable`
    - `ValueListenable<bool> errorListenable`
    - `void reload()`

## Data sources
- Connectivity: [ConnectivityCubit](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/bloc/connectivity_cubit.dart:43:0-87:1) ([lib/presentation/bloc/connectivity_cubit.dart](cci:7://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/bloc/connectivity_cubit.dart:0:0-0:0))
  - `isOnline`, `checking`, `firstRun`
- WebView state: [CustomWebViewState](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:14:0-113:1) ([lib/webview.dart](cci:7://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:0:0-0:0))
  - `isLoadingListenable`, `errorListenable`, [reload()](cci:1://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:28:2-28:40)

## Show/Hide rules
- Suppress entirely when `firstRun || checking`.
- Loading scrim shows when `isLoading && isOnline && !hasError`.
- Blocking scrim shows when `!isOnline || hasError`.
- Blocking scrim absorbs pointer events. Reload button appears only on error.

## Lifecycle notes
- Error is reset on `onPageStarted`.
- Notifiers disposed in [dispose()](cci:1://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/main.dart:89:2-92:3).
- If app resumes and had an error, WebView auto-reloads.

## Integration
- Use [WebViewContainer(url: ...)](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/widgets/webview_container.dart:9:0-15:1) anywhere WebView content is displayed.
- This scrim is local to WebView only and does not replace the global offline overlay.
- Global startup overlay remains gated by a ~3s grace period to prevent false flashes.

## QA checklist
- Play/Pause and bottom navigation remain usable when the WebView scrim is visible.
- No startup flicker on cold launch.
- Reload recovers after transient network errors.
- Donate external browser behavior is unaffected.

## Troubleshooting
- If the scrim never hides, verify [ConnectivityCubit](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/presentation/bloc/connectivity_cubit.dart:43:0-87:1) emissions (`isOnline`, `checking`, `firstRun`).
- Confirm [CustomWebViewState](cci:2://file:///Users/paulhenshaw/Desktop/Pacifica2/lib/webview.dart:14:0-113:1) notifiers are wired and receiving updates.
- Check WebView errors (CORS, navigation, HTTP status).