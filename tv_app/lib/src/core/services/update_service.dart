import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UpdateService {

  //final Dio _dio = Dio();

  Future<void> checkUpdate() async {

    final packageInfo =
        await PackageInfo.fromPlatform();

    final currentVersion =
        packageInfo.version;

   debugPrint(
    "Current Version: $currentVersion",
    );

    // API sẽ bổ sung sau

  }
}