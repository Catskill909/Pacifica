import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatelessWidget {
  final String url;

  const CustomWebView({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB81717), // Set the background color here
      child: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        zoomEnabled: false, // Disable zoom
        navigationDelegate: (NavigationRequest request) {
          // Handle navigation actions, such as URL changes
          return NavigationDecision.navigate;
        },
        onWebViewCreated: (WebViewController webViewController) {
          // Disable scrolling and bounce effect
          webViewController.runJavascript(
              "document.body.style.overflow = 'hidden';" // Disable scrolling
                  "document.documentElement.style.overflow = 'hidden';" // Additional line to ensure no scrolling on the HTML element
          );
        },

        onPageStarted: (String url) {
          // Perform actions when page loading starts
        },
        onPageFinished: (String url) {
          // Perform actions when page loading finishes
        },
        onWebResourceError: (WebResourceError error) {
          // Handle web resource errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading page: ${error.description}')),
          );
        },
        gestureNavigationEnabled: false, // Disable gesture navigation to prevent scroll
      ),
    );
  }
}
