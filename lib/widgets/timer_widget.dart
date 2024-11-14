import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerWidget extends StatefulWidget {
  final String initialTime;
  final String matchId;
  final Color? color;

  const TimerWidget({
    Key? key,
    required this.initialTime,
    required this.matchId,
    this.color
  }) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  late Duration _remainingTime;
  late SharedPreferences _prefs;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    _prefs = await SharedPreferences.getInstance();
    final String timeKey = 'match_${widget.matchId}_time';
    final String initialTimeKey = 'match_${widget.matchId}_initial';

    final int? storedStartTime = _prefs.getInt(timeKey);
    final String? storedInitialTime = _prefs.getString(initialTimeKey);

    final Duration currentInitialDuration = _parseTime(widget.initialTime);

    // Check if this is a new listing by comparing initial times
    bool isNewListing = storedInitialTime != widget.initialTime;

    if (storedStartTime == null || isNewListing) {
      // First time seeing this match or new listing
      _remainingTime = currentInitialDuration;
      await _prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setString(initialTimeKey, widget.initialTime);
    } else {
      final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(storedStartTime);
      final Duration elapsed = DateTime.now().difference(startTime);
      _remainingTime = currentInitialDuration - elapsed;

      // If timer has expired, treat as new listing
      if (_remainingTime.isNegative) {
        _remainingTime = currentInitialDuration;
        await _prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
        await _prefs.setString(initialTimeKey, widget.initialTime);
      }
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _startTimer();
    }
  }

  Duration _parseTime(String time) {
    try {
      int days = 0;
      int hours = 0;
      int minutes = 0;
      int seconds = 0;

      final parts = time.toLowerCase().split(' ');
      for (int i = 0; i < parts.length; i += 2) {
        if (i + 1 >= parts.length) break;
        final value = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final unit = parts[i + 1].trim();

        if (unit.startsWith('d')) {
          days = value;
        } else if (unit.startsWith('h')) {
          hours = value;
        } else if (unit.startsWith('m')) {
          minutes = value;
        } else if (unit.startsWith('s')) {
          seconds = value;
        }
      }

      return Duration(
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
    } catch (e) {
      print('Error parsing time: $e');
      return const Duration();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          } else {
            _timer.cancel();
          }
        });
      }
    });
  }

  String _formatTime() {
    if (_remainingTime.inSeconds <= 0) {
      return 'Starting Soon';
    }

    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours.remainder(24);
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days d');
    }
    if (hours > 0 || days > 0) {
      parts.add('$hours h');
    }
    if (minutes > 0 || hours > 0 || days > 0) {
      parts.add('$minutes m');
    }
    parts.add('$seconds s');

    return parts.join(' ');
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Text(
      _formatTime(),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: widget.color ?? const Color(0xFF8B1E65),
      ),
    );
  }
}