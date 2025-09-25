import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pacifica2/webview.dart';
import 'package:pacifica2/presentation/widgets/webview_scrim.dart';
import 'package:pacifica2/presentation/bloc/connectivity_cubit.dart';

/// Wraps the WebView and overlays a scrim only over the WebView area when
/// loading, offline, or error. Other UI (play/pause, nav) remains usable.
class WebViewContainer extends StatefulWidget {
  final String url;
  const WebViewContainer({super.key, required this.url});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  final GlobalKey<CustomWebViewState> _webKey = GlobalKey<CustomWebViewState>();
  // Stable fallbacks until the WebView state is available
  final ValueNotifier<bool> _falseVN = ValueNotifier<bool>(false);
  
  // Public method to force refresh the WebView
  void forceRefresh() {
    _webKey.currentState?.forceRefresh();
  }

  @override
  void dispose() {
    _falseVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webState = _webKey.currentState;
    final loadingListenable = webState?.isLoadingListenable ?? _falseVN;
    final errorListenable = webState?.errorListenable ?? _falseVN;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomWebView(key: _webKey, url: widget.url),
        BlocBuilder<ConnectivityCubit, ConnectivityState>(
          buildWhen: (a, b) => a.isOnline != b.isOnline || a.checking != b.checking || a.firstRun != b.firstRun,
          builder: (context, conn) {
            return ValueListenableBuilder<bool>(
              valueListenable: loadingListenable,
              builder: (_, isLoading, __) {
                return ValueListenableBuilder<bool>(
                  valueListenable: errorListenable,
                  builder: (_, hasError, __) {
                    return WebViewScrim(
                      isOnline: conn.isOnline,
                      checking: conn.checking,
                      firstRun: conn.firstRun,
                      isLoading: isLoading,
                      hasError: hasError,
                      onReload: hasError ? () => _webKey.currentState?.reload() : null,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
