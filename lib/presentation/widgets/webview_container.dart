import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/connectivity_cubit.dart';
import '../../webview.dart';
import 'webview_scrim.dart';

class WebViewContainer extends StatefulWidget {
  final String url;

  const WebViewContainer({super.key, required this.url});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  Key _webViewKey = UniqueKey();
  Timer? _reloadTimer;

  @override
  void didUpdateWidget(covariant WebViewContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No special handling needed; internal WebView reacts to URL changes.
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _webViewKey = UniqueKey();
      });
    });
  }

  void _reloadNow() {
    if (!mounted) return;
    setState(() {
      _webViewKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connState = context.watch<ConnectivityCubit>().state;
    final bool showOffline = !connState.isOnline && !connState.firstRun && !connState.checking;

    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      listener: (context, state) {
        if (state.isOnline) {
          // Debounce a bit to allow network to settle before reload
          _scheduleReload();
        } else {
          // If we go offline, cancel any pending reloads
          _reloadTimer?.cancel();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If offline, do not render the WebView at all to avoid showing error pages.
          if (showOffline)
            Container(color: Colors.black)
          else
            // Keep the WebView implementation unchanged; rebuild with a new key to force reload
            CustomWebView(key: _webViewKey, url: widget.url),
          if (showOffline)
            WebViewScrim(
              online: connState.isOnline,
              onRetry: _reloadNow,
              showRetry: true,
            ),
        ],
      ),
    );
  }
}
