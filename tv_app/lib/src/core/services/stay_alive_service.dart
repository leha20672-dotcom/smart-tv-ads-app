import 'dart:async';
import 'package:flutter/foundation.dart';

class StayAliveService {

  static Timer? _timer;

  static void start(
    VoidCallback callback,
  ) {

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {

        callback();

      },
    );
  }

  static void stop() {
    _timer?.cancel();
  }
}