import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Simple connectivity + internet access checker
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio;

  static const String _probeUrl = 'https://www.google.com/generate_204';
  static const Duration _timeout = Duration(milliseconds: 1500);

  ConnectivityService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = _timeout
      ..receiveTimeout = _timeout
      ..sendTimeout = _timeout;
  }

  Future<bool> initialStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasAnyTransport = results.any((r) => r != ConnectivityResult.none);
      if (!hasAnyTransport) return false;
      return await hasInternet();
    } catch (_) {
      return await hasInternet();
    }
  }

  /// Returns true if the device has internet reachability.
  Future<bool> hasInternet() async {
    try {
      final res = await _dio.head(
        _probeUrl,
        options: Options(
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      );
      return res.statusCode == 204 || (res.statusCode ?? 0) >= 200;
    } catch (_) {
      return false;
    }
  }

  /// Emits true/false when connectivity changes and after verifying internet.
  Stream<bool> connectivityStream() async* {
    yield await initialStatus();

    await for (final results in _connectivity.onConnectivityChanged) {
      final hasAnyTransport = results.any((r) => r != ConnectivityResult.none);
      if (!hasAnyTransport) {
        yield false;
      } else {
        yield await hasInternet();
      }
    }
  }
}
