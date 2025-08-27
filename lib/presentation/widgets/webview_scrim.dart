import 'package:flutter/material.dart';

class WebViewScrim extends StatelessWidget {
  final bool online;
  final VoidCallback? onRetry;
  final bool showRetry;

  const WebViewScrim({
    super.key,
    required this.online,
    this.onRetry,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          color: const Color(0xD9000000), // ~85% black
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  "You're Offline",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Content will reload automatically once the internet is back.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                if (showRetry) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: online ? onRetry : null,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A)),
                      child: const Text(
                        'Retry now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
