import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final String url;

  const CustomWebView({Key? key, required this.url}) : super(key: key);

  @override
  CustomWebViewState createState() => CustomWebViewState();
}

class CustomWebViewState extends State<CustomWebView> with WidgetsBindingObserver {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes, reload the webview
      _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB81717), // Background color
      child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        onPageStarted: (String url) {
          // Perform actions when page loading starts
        },
        onPageFinished: (String url) {
          // Perform actions when page loading finishes
        },
        onWebResourceError: (WebResourceError error) {
          // Improved error handling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading page: ${error.description}')),
          );
        },
        gestureNavigationEnabled: false,
      ),
    );
  }
}
