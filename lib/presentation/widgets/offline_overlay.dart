import 'package:flutter/material.dart';
// No Bloc imports needed; overlay is passive and auto-hides when connectivity returns.

class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: Colors.black54,
        child: Center(
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
            child: DefaultTextStyle.merge(
              style: const TextStyle(decoration: TextDecoration.none, decorationColor: Colors.transparent),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "You're Offline",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The radio needs internet to play. This alert closes automatically once the internet is restored.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                    textAlign: TextAlign.center,
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
