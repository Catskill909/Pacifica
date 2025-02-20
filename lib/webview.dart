import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer'; // Import the developer library for logging

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
            setState(() => _isLoading = true);
            log('Loading page: $url');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            log('Finished loading page: $url');
          },
          onWebResourceError: (WebResourceError error) {
            log('Error loading page: ${error.description}');
            _errorOccurred = true;
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
          color: const Color(0xFFB81717), // Set the background color
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
