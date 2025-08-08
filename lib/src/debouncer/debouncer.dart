import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  final int durationInSeconds;
  final VoidCallback onComplete;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _startTime;

  Debouncer({required this.durationInSeconds, required this.onComplete});

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _startTime = DateTime.now();

    _timer = Timer(Duration(seconds: durationInSeconds), () {
      _isRunning = false;
      onComplete();
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _startTime = null;
  }

  bool get isRunning => _isRunning;

  int get timeLeft {
    if (!_isRunning || _startTime == null) return 0;

    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    final remaining = durationInSeconds - elapsed;

    return remaining > 0 ? remaining : 0;
  }
}
