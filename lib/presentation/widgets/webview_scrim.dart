import 'package:flutter/material.dart';

/// Lightweight overlay that covers only the WebView area.
///
/// Display rules (computed by parent):
/// - Loading: show spinner with subtle dim background.
/// - Offline or Error: show message card and optional Reload button.
/// - Suppressed during app first-run or active connectivity checking.
class WebViewScrim extends StatelessWidget {
  final bool isOnline;
  final bool checking;
  final bool firstRun;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onReload;

  const WebViewScrim({
    super.key,
    required this.isOnline,
    required this.checking,
    required this.firstRun,
    required this.isLoading,
    required this.hasError,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    // Gate during startup/checking to avoid flicker
    if (firstRun || checking) return const SizedBox.shrink();

    // Loading-only, while online and no error
    if (isLoading && isOnline && !hasError) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
      );
    }

    // Offline or error state
    final shouldShowBlocking = (!isOnline) || hasError;
    if (!shouldShowBlocking) return const SizedBox.shrink();

    final title = !isOnline ? "You're Offline" : 'Page failed to load';
    final message = !isOnline
        ? 'The radio needs internet to play. Please reconnect and try again.'
        : 'Please check your connection and try reloading the page.';

    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade300, height: 1.3)),
                  const SizedBox(height: 16),
                  if (onReload != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: onReload,
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


