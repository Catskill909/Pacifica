import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final String url;

  const CustomWebView({Key? key, required this.url}) : super(key: key);

  @override
  CustomWebViewState createState() => CustomWebViewState();
}

class CustomWebViewState extends State<CustomWebView> with WidgetsBindingObserver {
  bool _isLoading = true;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay the WebView rendering
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 300),
          child: WebView(
            initialUrl: widget.url,
            javascriptMode: JavascriptMode.unrestricted,
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading page: ${error.description}')),
              );
            },
            gestureNavigationEnabled: false,
          ),
        ),
        _isLoading
            ? Container(
          alignment: Alignment.center,
          color: Colors.transparent, // Or any other color that suits your app
          child: const CircularProgressIndicator(),
        )
            : Container(),
      ],
    );
  }
}
