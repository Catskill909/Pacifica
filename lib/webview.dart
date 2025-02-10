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
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            log('Error loading page: ${error.description}'); // Use log instead of print
            _errorOccurred = true;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
