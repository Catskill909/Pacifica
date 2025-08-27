import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer';

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

  // Public listenables to allow overlays/scrims to rebuild on state changes
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _errorNotifier = ValueNotifier<bool>(false);

  // Public getters/listenables for outside widgets
  bool get isLoading => _isLoadingNotifier.value;
  bool get hasError => _errorNotifier.value;
  ValueListenable<bool> get isLoadingListenable => _isLoadingNotifier;
  ValueListenable<bool> get errorListenable => _errorNotifier;
  void reload() => _controller.reload();

  @override
  void initState() {
    super.initState();
    log('WebView initialized');
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
      ..loadRequest(Uri.parse(widget.url));
    log('initState completed');
  }

  @override
  void didUpdateWidget(CustomWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      log('URL changed from ${oldWidget.url} to ${widget.url}');
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  void dispose() {
    log('WebView disposed');
    WidgetsBinding.instance.removeObserver(this);
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
    log('dispose completed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('didChangeAppLifecycleState: $state');
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _errorOccurred) {
      _controller.reload();
      _errorOccurred = false;
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

