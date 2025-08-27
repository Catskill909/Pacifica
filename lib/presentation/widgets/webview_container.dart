import 'package:flutter/material.dart';
import 'package:pacifica2/webview.dart';

// Thin wrapper to preserve existing API while delegating to the current
// CustomWebView implementation. This keeps the UI and behavior unchanged.
class WebViewContainer extends StatelessWidget {
  final String url;
  const WebViewContainer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return CustomWebView(url: url);
  }
}
