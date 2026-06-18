import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IdleClockScreen extends StatefulWidget{
  const IdleClockScreen({super.key});

  @override
  State<IdleClockScreen> createState() => _IdleClockScreenState();
}

class _IdleClockScreenState extends State<IdleClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm:ss').format(_now);
    final dateText = DateFormat('dd/MM/yyyy').format(_now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dateText,
              style: const TextStyle(
                color: Colors.white70, 
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có lịch phát quảng cáo',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    ); 
  }
}