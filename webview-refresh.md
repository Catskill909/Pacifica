# WebView Refresh Issue Analysis & Ground Plan

## CRITICAL ISSUE IDENTIFIED
**Date:** September 24, 2025  
**Status:** iOS-SPECIFIC PRODUCTION BUG - WebView content not refreshing properly  
**Impact:** iOS users seeing stale "Now Playing" information (Android working fine)

## DYNAMIC CONTENT ANALYSIS

### URL Content Structure
The WebView URLs contain **HIGHLY DYNAMIC CONTENT** that should refresh every 10 seconds:

#### HD1 URL: `https://docs.pacifica.org/kpft/hd1/`
- **JavaScript Auto-Refresh:** `setInterval(get_data, 10000)` - fetches new data every 10 seconds
- **Dynamic Elements:**
  - Current show name (`cur_show`)
  - Host name (`current_host`) 
  - Show times (`current_time`)
  - Host photos (`host_pix`)
  - Current song title (`current_song_title`)
  - Current artist (`current_song_artist`)
  - Next show information
- **Data Source:** Fetches from `proxy.php` endpoint every 10 seconds
- **Expected Behavior:** Content should continuously update with live radio information

#### HD2 URL: `https://docs.pacifica.org/kpft/hd2/`
- **Same Dynamic Structure** as HD1
- **Same 10-second refresh interval**
- **Same live data fetching mechanism**

#### HD3 URL: `https://docs.pacifica.org/kpft/hd3/`
- **Static Content** - No JavaScript refresh mechanism
- Shows fixed "KPFT 90.1 FM - HD3" and "Houston's Community Station"

## ROOT CAUSE ANALYSIS

### iOS-Specific WebView Issues

1. **iOS WKWebView JavaScript Suspension**
   - iOS aggressively suspends JavaScript `setInterval` in background WebViews
   - Tab switching pauses JavaScript execution entirely
   - Memory pressure causes JavaScript timers to be cleared

2. **iOS App Lifecycle Interference**
   - iOS pauses JavaScript when app goes to background
   - WebView focus/blur events behave differently than Android
   - JavaScript execution context gets reset more frequently

3. **URL Change Detection (General Issue)**
   ```dart
   void didUpdateWidget(CustomWebView oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.url != widget.url) {
       log('URL changed from ${oldWidget.url} to ${widget.url}');
       _controller.loadRequest(Uri.parse(widget.url));
     }
   }
   ```
   - Only reloads when URL changes
   - **SAME URL = NO RELOAD** - this is the core issue
   - When switching between tabs and returning, same URL doesn't trigger refresh

3. **Missing Cache Control Headers**
   - No explicit cache-control headers being set
   - WebView using default caching behavior
   - JavaScript execution may be cached/suspended

4. **JavaScript Execution Context**
   - `setInterval` may be paused when WebView loses focus
   - Background JavaScript execution may be throttled
   - Page lifecycle events not properly handled

## EVIDENCE OF PREVIOUS FUNCTIONALITY

Based on user statement "This used to work", possible causes for regression:

1. **Flutter WebView Plugin Updates**
   - Recent webview_flutter plugin updates may have changed caching behavior
   - New default cache policies introduced

2. **Android WebView System Updates**
   - Android System WebView updates can change JavaScript execution
   - Background tab throttling policies may have changed

3. **Server-Side Changes**
   - Caching headers may have been added to the docs.pacifica.org server
   - Content-Security-Policy changes affecting JavaScript execution

## GROUND PLAN FOR RESOLUTION

### PHASE 1: iOS-SPECIFIC IMMEDIATE FIXES (Priority: CRITICAL)

1. **iOS JavaScript Timer Revival**
   ```dart
   // iOS-specific periodic refresh to restart suspended JavaScript
   Timer.periodic(const Duration(seconds: 30), (timer) {
     _controller.runJavaScript('''
       if (typeof get_data === 'function') {
         get_data(); // Restart the data fetch
       }
     ''');
   });
   ```

2. **iOS App Lifecycle Handling**
   ```dart
   if (state == AppLifecycleState.resumed && defaultTargetPlatform == TargetPlatform.iOS) {
     forceRefresh(); // Restart JavaScript on app resume
   }
   ```

3. **Cache-Busting for All Platforms**
   ```dart
   _controller = WebViewController()
     ..setJavaScriptMode(JavaScriptMode.unrestricted)
     ..clearCache() // Add this
     ..clearLocalStorage() // Add this
   ```

### PHASE 2: CACHE CONTROL IMPLEMENTATION (Priority: HIGH)

1. **Disable WebView Caching**
   ```dart
   _controller = WebViewController()
     ..setUserAgent('KPFT-App/1.0 (no-cache)')
     ..clearCache()
   ```

2. **Add Cache-Busting Query Parameters**
   ```dart
   String _addCacheBuster(String url) {
     final timestamp = DateTime.now().millisecondsSinceEpoch;
     final separator = url.contains('?') ? '&' : '?';
     return '$url${separator}_t=$timestamp';
   }
   ```

3. **Implement Periodic Refresh**
   ```dart
   Timer? _refreshTimer;
   
   void _startPeriodicRefresh() {
     _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       _controller.reload();
     });
   }
   ```

### PHASE 3: ADVANCED SOLUTIONS (Priority: MEDIUM)

1. **WebView Lifecycle Management**
   - Implement proper pause/resume handling
   - Ensure JavaScript continues execution in background

2. **Custom Headers Implementation**
   ```dart
   _controller.loadRequest(
     Uri.parse(widget.url),
     headers: {
       'Cache-Control': 'no-cache, no-store, must-revalidate',
       'Pragma': 'no-cache',
       'Expires': '0',
     },
   );
   ```

3. **Tab Switch Refresh Logic**
   ```dart
   onTabChanged: (streamId) {
     setState(() {
       _currentIndex = ['HD1', 'HD2', 'HD3'].indexOf(streamId);
       _currentWebViewUrl = webViewUrls[streamId] ?? _currentWebViewUrl;
     });
     // FORCE REFRESH EVEN FOR SAME URL
     _forceWebViewRefresh();
   }
   ```

### PHASE 4: VALIDATION & TESTING (Priority: HIGH)

1. **Test Scenarios**
   - Switch between HD1 ↔ HD2 ↔ HD1 rapidly
   - Leave app in background for 5+ minutes, return and check content
   - Monitor JavaScript console for `get_data()` execution
   - Verify 10-second refresh intervals are working

2. **Performance Monitoring**
   - Monitor memory usage with frequent refreshes
   - Test on various Android versions
   - Validate on tablets vs phones

## IMPLEMENTATION PRIORITY

1. **IMMEDIATE (Today):** Add cache clearing and force refresh on tab switches
2. **SHORT TERM (This Week):** Implement cache-busting and periodic refresh
3. **MEDIUM TERM (Next Week):** Advanced WebView lifecycle management
4. **ONGOING:** Monitoring and performance optimization

## SUCCESS CRITERIA

- [ ] HD1/HD2 content updates every 10 seconds automatically
- [ ] Switching tabs and returning shows fresh content immediately  
- [ ] JavaScript `setInterval` executes continuously
- [ ] No memory leaks from frequent refreshes
- [ ] Background/foreground transitions maintain refresh functionality

## RISK ASSESSMENT

- **LOW RISK:** Cache clearing and query parameter cache-busting
- **MEDIUM RISK:** Periodic refresh timers (memory management)
- **HIGH RISK:** Major WebView configuration changes (could break existing functionality)

---

**Next Action:** Implement Phase 1 diagnostics immediately to confirm root cause and restore production functionality.
