import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer';
import 'dart:async';

class CustomWebView extends StatefulWidget {
  final String url;

  const CustomWebView({super.key, required this.url});

  @override
  CustomWebViewState createState() => CustomWebViewState();
}

class CustomWebViewState extends State<CustomWebView>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _errorOccurred = false;
  String? _lastLoadedUrl; // Track last loaded URL for force refresh detection
  Timer? _iosRefreshTimer; // iOS-specific timer to ensure JavaScript keeps running

  // Public listenables to allow overlays/scrims to rebuild on state changes
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _errorNotifier = ValueNotifier<bool>(false);

  // Public getters/listenables for outside widgets
  bool get isLoading => _isLoadingNotifier.value;
  bool get hasError => _errorNotifier.value;
  ValueListenable<bool> get isLoadingListenable => _isLoadingNotifier;
  ValueListenable<bool> get errorListenable => _errorNotifier;
  void reload() => _controller.reload();
  
  // Force refresh with cache busting
  void forceRefresh() {
    final cacheBustedUrl = _addCacheBuster(widget.url);
    log('Force refreshing with cache buster: $cacheBustedUrl');
    _controller.loadRequest(Uri.parse(cacheBustedUrl));
  }
  
  // Add cache-busting timestamp to URL
  String _addCacheBuster(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_t=$timestamp';
  }
  
  // iOS-specific: Start periodic refresh to combat JavaScript suspension
  void _startIosPeriodicRefresh() {
    _iosRefreshTimer?.cancel();
    _iosRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      log('iOS periodic refresh - ensuring JavaScript stays active');
      // Inject JavaScript to restart the setInterval if it was suspended
      _controller.runJavaScript('''
        if (typeof get_data === 'function') {
          console.log('Restarting get_data interval from iOS refresh');
          get_data(); // Call immediately
        }
      ''');
    });
  }

  @override
  void initState() {
    super.initState();
    log('WebView initialized');
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..clearCache() // Clear cache on initialization
      ..clearLocalStorage() // Clear local storage
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorOccurred = false;
            });
            _isLoadingNotifier.value = true;
            _errorNotifier.value = false;
            log('Loading page: $url');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _isLoadingNotifier.value = false;
            log('Finished loading page: $url');
          },
          onWebResourceError: (WebResourceError error) {
            log('Error loading page: ${error.description}');
            setState(() => _errorOccurred = true);
            _errorNotifier.value = true;
          },
        ),
      )
      ..loadRequest(Uri.parse(_addCacheBuster(widget.url)));
    _lastLoadedUrl = widget.url;
    
    // iOS-specific: Start periodic refresh to keep JavaScript alive
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _startIosPeriodicRefresh();
    }
    
    log('initState completed with cache-busted URL');
  }

  @override
  void didUpdateWidget(CustomWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRITICAL FIX: Always refresh, even for same URL (for live content)
    if (oldWidget.url != widget.url || _lastLoadedUrl != widget.url) {
      log('URL changed from ${oldWidget.url} to ${widget.url} OR force refresh needed');
      final cacheBustedUrl = _addCacheBuster(widget.url);
      _controller.loadRequest(Uri.parse(cacheBustedUrl));
      _lastLoadedUrl = widget.url;
    }
  }

  @override
  void dispose() {
    log('WebView disposed');
    WidgetsBinding.instance.removeObserver(this);
    _iosRefreshTimer?.cancel(); // Clean up iOS timer
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
    log('dispose completed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('didChangeAppLifecycleState: $state');
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_errorOccurred) {
        _controller.reload();
        _errorOccurred = false;
      } else {
        // iOS-specific: Force refresh on resume to restart JavaScript timers
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          log('iOS app resumed - force refreshing WebView to restart JavaScript');
          forceRefresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFB81717),
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
        if (_isLoading)
          Container(
            alignment: Alignment.center,
            color: Colors.white,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}

