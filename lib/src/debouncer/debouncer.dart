import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  final int durationInSeconds;
  final VoidCallback onComplete;
  final VoidCallback onTick;

  Timer? _ticker;
  int _remaining;
  bool _isRunning = false;

  Debouncer({
    required this.durationInSeconds,
    required this.onComplete,
    required this.onTick,
  }) : _remaining = durationInSeconds;

  int get timeLeft => _remaining;

  void start() {
    if (_isRunning) return;
    _isRunning = false;
    stop(); // Stop any existing timer
    _remaining = durationInSeconds;
    onTick(); // Initial tick

    // Repeating timer every 1 second
    _ticker = Timer.periodic(Duration(seconds: 1), (timer) {
      _remaining--;

      if (_remaining <= 0) {
        _remaining = 0;
        onTick(); // Update UI one last time
        stop(); // Stop the timer
        onComplete(); // Call completion callback
      } else {
        onTick(); // Update UI each tick
      }
    });
  }

  void stop() {
    _ticker?.cancel();
    _isRunning = true;
    _ticker = null;
  }

  bool get isRunning => _isRunning;
}
