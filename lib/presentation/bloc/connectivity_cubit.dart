import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/connectivity_service.dart';

class ConnectivityState extends Equatable {
  final bool isOnline;
  final bool checking;
  final bool firstRun;
  final bool dismissed; // suppress offline UI until next connectivity change

  const ConnectivityState({
    required this.isOnline,
    required this.checking,
    required this.firstRun,
    required this.dismissed,
  });

  factory ConnectivityState.initial() => const ConnectivityState(
        isOnline: true,
        checking: true,
        firstRun: true,
        dismissed: false,
      );

  ConnectivityState copyWith({
    bool? isOnline,
    bool? checking,
    bool? firstRun,
    bool? dismissed,
  }) => ConnectivityState(
        isOnline: isOnline ?? this.isOnline,
        checking: checking ?? this.checking,
        firstRun: firstRun ?? this.firstRun,
        dismissed: dismissed ?? this.dismissed,
      );

  @override
  List<Object?> get props => [isOnline, checking, firstRun, dismissed];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;
  Timer? _startupGraceTimer;

  ConnectivityCubit({required ConnectivityService service})
      : _service = service,
        super(ConnectivityState.initial());

  void initialize() {
    _sub?.cancel();
    
    // Start 5-second grace period to prevent startup modal false positives
    _startupGraceTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed) {
        emit(state.copyWith(firstRun: false));
      }
    });
    
    _sub = _service.connectivityStream().listen((isOnline) {
      final isInGracePeriod = _startupGraceTimer?.isActive ?? false;
      emit(state.copyWith(
        isOnline: isOnline,
        checking: false,
        firstRun: isInGracePeriod,
        dismissed: false,
      ));
    });
  }

  Future<void> checkNow() async {
    emit(state.copyWith(checking: true));
    final online = await _service.hasInternet();
    final statusChanged = online != state.isOnline;
    emit(state.copyWith(
      isOnline: online,
      checking: false,
      firstRun: false,
      dismissed: statusChanged ? false : state.dismissed,
    ));
  }

  /// Suppress offline UI until the next connectivity state change
  void dismissUntilChange() {
    if (!state.isOnline && !state.dismissed) {
      emit(state.copyWith(dismissed: true));
    }
  }

  @override
  Future<void> close() async {
    _startupGraceTimer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
