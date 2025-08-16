import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/connectivity_cubit.dart';

class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final checking = context.select<ConnectivityCubit, bool>((c) => c.state.checking);

    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(decoration: TextDecoration.none, decorationColor: Colors.transparent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "You're Offline",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The radio needs internet to play. Please reconnect and try again.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none, decorationColor: Colors.transparent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: checking
                              ? null
                              : () async {
                                  await context.read<ConnectivityCubit>().checkNow();
                                },
                          child: checking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            context.read<ConnectivityCubit>().dismissUntilChange();
                          },
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A)),
                          child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
