import 'dart:async';

import 'package:flutter/widgets.dart';

/// Centralized football refresh policy: live vs idle intervals, lifecycle pause,
/// multi-listener ticks, single-flight dedupe, and exponential backoff.
class FootballRefreshManager with WidgetsBindingObserver {
  FootballRefreshManager._();
  static final FootballRefreshManager instance = FootballRefreshManager._();

  static const liveInterval = Duration(seconds: 60);
  static const idleInterval = Duration(minutes: 4);
  static const minManualGap = Duration(seconds: 8);

  /// When true, skips periodic timers (widget/unit tests).
  static bool disablePeriodicRefresh = false;

  bool _started = false;
  bool _foreground = true;
  bool _hasLive = false;

  final Map<String, Future<void>> _inFlight = {};
  final Map<String, DateTime> _lastSuccess = {};
  final Map<String, DateTime> _lastAttempt = {};
  final Map<String, int> _failStreak = {};
  final Map<String, DateTime> _rateLimitedUntil = {};
  final Set<VoidCallback> _listeners = {};

  Timer? _timer;

  bool get isForeground => _foreground;
  bool get hasLiveMatches => _hasLive;
  int get listenerCount => _listeners.length;

  /// Register a tick listener. Starts lifecycle observation on first listener.
  void addListener(VoidCallback onTick) {
    _listeners.add(onTick);
    _ensureStarted();
  }

  void removeListener(VoidCallback onTick) {
    _listeners.remove(onTick);
    if (_listeners.isEmpty) {
      stop();
    }
  }

  /// Backward-compatible single-callback start (replaces previous listener set).
  void start(VoidCallback onTick) {
    _listeners
      ..clear()
      ..add(onTick);
    _ensureStarted();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  void _ensureStarted() {
    if (_started) {
      _reschedule();
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _reschedule();
  }

  void setHasLiveMatches(bool value) {
    if (_hasLive == value) return;
    _hasLive = value;
    _reschedule();
  }

  Duration get currentInterval => _hasLive ? liveInterval : idleInterval;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final next = state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    final wasFg = _foreground;
    _foreground = next;
    if (!wasFg && _foreground) {
      _fire();
    }
    _reschedule();
  }

  void _reschedule() {
    _timer?.cancel();
    if (!_foreground || _listeners.isEmpty || disablePeriodicRefresh) return;
    final interval = currentInterval;
    _timer = Timer.periodic(interval, (_) {
      if (_foreground && !disablePeriodicRefresh) _fire();
    });
  }

  void _fire() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  /// Returns false if this request should be skipped (deduped / rate-limited).
  bool shouldAllow(String key, {bool force = false}) {
    if (_inFlight.containsKey(key)) return false;
    final limited = _rateLimitedUntil[key];
    if (limited != null && DateTime.now().isBefore(limited)) return false;
    if (!force) {
      final last = _lastAttempt[key];
      if (last != null &&
          DateTime.now().difference(last) < const Duration(seconds: 20)) {
        return false;
      }
    } else {
      final last = _lastAttempt[key];
      if (last != null && DateTime.now().difference(last) < minManualGap) {
        return false;
      }
    }
    return true;
  }

  Future<T> runSingleFlight<T>(
    String key,
    Future<T> Function() action, {
    bool force = false,
  }) async {
    final existing = _inFlight[key];
    if (existing != null) {
      await existing;
      throw StateError('deduped');
    }
    if (!shouldAllow(key, force: force)) {
      throw StateError('throttled');
    }

    _lastAttempt[key] = DateTime.now();
    final isTesting = const bool.fromEnvironment('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final timeout = isTesting ? const Duration(milliseconds: 250) : const Duration(seconds: 45);
    final future = () async {
      try {
        final result = await action().timeout(timeout);
        _lastSuccess[key] = DateTime.now();
        _failStreak[key] = 0;
        _rateLimitedUntil.remove(key);
        return result;
      } catch (e) {
        _failStreak[key] = (_failStreak[key] ?? 0) + 1;
        final streak = _failStreak[key]!;
        final msg = e.toString().toLowerCase();
        final isPermanent = msg.contains('404') ||
            msg.contains('401') ||
            msg.contains('403') ||
            msg.contains('unknown league');
        if (isPermanent) {
          rethrow;
        }
        if (msg.contains('429') || msg.contains('rate')) {
          final retryMatch = RegExp(r'retry[- ]after[:\s]*(\d+)').firstMatch(msg);
          final hinted = int.tryParse(retryMatch?.group(1) ?? '');
          final backoff = Duration(
            seconds: (hinted ?? (30 * streak)).clamp(30, 300),
          );
          _rateLimitedUntil[key] = DateTime.now().add(backoff);
        } else if (streak > 1) {
          final backoff =
              Duration(seconds: (5 * (1 << (streak - 1))).clamp(5, 120));
          _rateLimitedUntil[key] = DateTime.now().add(backoff);
        }
        rethrow;
      } finally {
        _inFlight.remove(key);
      }
    }();

    _inFlight[key] = future.then((_) {}, onError: (_) {});
    return future;
  }

  DateTime? lastSuccess(String key) => _lastSuccess[key];

  /// Test helper — clears runtime state without disposing the singleton.
  void resetForTest() {
    _timer?.cancel();
    _timer = null;
    _inFlight.clear();
    _lastSuccess.clear();
    _lastAttempt.clear();
    _failStreak.clear();
    _rateLimitedUntil.clear();
    _listeners.clear();
    _hasLive = false;
    _foreground = true;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }
}
