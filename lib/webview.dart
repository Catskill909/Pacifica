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
  String _lastKnownContentStatus = ''; // Variable to store the last known content status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAndUpdateContentStatus(); // Fetch initial content status
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchAndUpdateContentStatus() async {
    // TODO: Implement the logic to fetch the current content status from your server
    // For example, it could be a timestamp or a hash value
    // Update _lastKnownContentStatus with the fetched value
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      String currentStatus = ''; // Fetch the current status from the server
      // TODO: Replace with actual fetch logic
      if (currentStatus != _lastKnownContentStatus) {
        _controller.reload(); // Reload only if content has changed
        _lastKnownContentStatus = currentStatus; // Update the last known status
      }
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
