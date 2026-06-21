import 'dart:async';

class WatchdogService {

  static Timer? timer;

  static void start(
    Function callback,
  ) {

    timer?.cancel();

    timer = Timer(
      const Duration(seconds: 30),
      () {

        callback();

      },
    );
  }

  static void reset(
    Function callback,
  ) {

    start(callback);

  }
}