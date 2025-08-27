import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Enhanced connectivity + internet access checker with multiple probes and retry logic
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio;

  static const List<String> _probeUrls = [
    'https://www.google.com/generate_204',
    'https://1.1.1.1/generate_204',
    'https://captive.apple.com/hotspot-detect.html',
  ];
  static const Duration _fastTimeout = Duration(milliseconds: 800);
  static const Duration _normalTimeout = Duration(milliseconds: 1500);

  ConnectivityService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = _fastTimeout
      ..receiveTimeout = _fastTimeout
      ..sendTimeout = _fastTimeout;
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
  /// Uses multiple probe URLs with retry logic to reduce false negatives.
  Future<bool> hasInternet() async {
    // Try fast probes first
    for (String url in _probeUrls) {
      if (await _probeUrl(url, _fastTimeout)) return true;
    }
    
    // If fast probes fail, try with longer timeout
    _dio.options.connectTimeout = _normalTimeout;
    _dio.options.receiveTimeout = _normalTimeout;
    _dio.options.sendTimeout = _normalTimeout;
    
    for (String url in _probeUrls) {
      if (await _probeUrl(url, _normalTimeout)) {
        // Reset to fast timeout for future calls
        _dio.options.connectTimeout = _fastTimeout;
        _dio.options.receiveTimeout = _fastTimeout;
        _dio.options.sendTimeout = _fastTimeout;
        return true;
      }
    }
    
    // Reset timeout settings
    _dio.options.connectTimeout = _fastTimeout;
    _dio.options.receiveTimeout = _fastTimeout;
    _dio.options.sendTimeout = _fastTimeout;
    
    return false;
  }
  
  /// Probe a specific URL for connectivity
  Future<bool> _probeUrl(String url, Duration timeout) async {
    try {
      final res = await _dio.head(
        url,
        options: Options(
          validateStatus: (code) => code != null && code >= 200 && code < 400,
          sendTimeout: timeout,
          receiveTimeout: timeout,
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
