import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/connectivity_cubit.dart';

class OfflineModal extends StatelessWidget {
  const OfflineModal({super.key});

  @override
  Widget build(BuildContext context) {
    final checking = context.select<ConnectivityCubit, bool>((c) => c.state.checking);

    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      listener: (context, state) {
        if (state.isOnline) {
          // Auto-close the modal when connectivity is restored
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
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
                const Text.rich(
                  TextSpan(
                    text: 'The radio needs internet to play. Please reconnect and try again.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
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
                                if (context.mounted && context.read<ConnectivityCubit>().state.isOnline) {
                                  Navigator.of(context, rootNavigator: true).maybePop();
                                }
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
                        onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A)),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
