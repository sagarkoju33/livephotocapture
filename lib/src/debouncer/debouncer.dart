import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  final int durationInSeconds;
  final VoidCallback onComplete;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _startTime;
  ValueNotifier<int> _timeLeftNotifier = ValueNotifier(0);

  Debouncer({required this.durationInSeconds, required this.onComplete});

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _startTime = DateTime.now();
    _timeLeftNotifier.value = durationInSeconds;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      final remaining = durationInSeconds - elapsed;
      if (remaining <= 0) {
        _timeLeftNotifier.value = 0;
        timer.cancel();
        _isRunning = false;
        onComplete();
      } else {
        _timeLeftNotifier.value = remaining;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _startTime = null;
    _timeLeftNotifier.value = 0;
  }

  bool get isRunning => _isRunning;

  ValueNotifier<int> get timeLeft => _timeLeftNotifier;

  void dispose() {
    _timeLeftNotifier.dispose();
    _timer?.cancel();
  }
}