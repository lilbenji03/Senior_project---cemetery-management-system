// lib/widgets/countdown_timer_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final TextStyle? style;
  final VoidCallback? onExpired;

  const CountdownTimerWidget({
    super.key,
    required this.expiresAt,
    this.style,
    this.onExpired,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    // Only start the timer if the expiry date is in the future
    if (_timeLeft != null && !_timeLeft!.isNegative) {
      _timer =
          Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    if (!mounted) return;
    final now = DateTime.now();
    final timeLeft = widget.expiresAt.difference(now);

    setState(() {
      _timeLeft = timeLeft;
    });

    if (timeLeft.isNegative && _timer?.isActive == true) {
      _timer?.cancel();
      // Notify the parent widget that the timer has expired
      widget.onExpired?.call();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (days > 0) return '$days day(s) $hours:$minutes:$seconds';
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == null) {
      return const SizedBox.shrink();
    }
    return Text(
      'Expires In: ${_formatDuration(_timeLeft!)}',
      style: widget.style ??
          TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
    );
  }
}
