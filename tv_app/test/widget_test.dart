import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tv_app/src/app.dart';
import 'package:tv_app/src/core/storage/storage_keys.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tv_app_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(StorageKeys.appBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('shows device registration screen when TV is not registered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TvAdsApp()));
    await tester.pump();

    expect(find.text('Dang ky TV'), findsOneWidget);
    expect(find.text('Backend URL'), findsOneWidget);
    expect(find.text('Device code'), findsOneWidget);
    expect(find.text('Dang ky va ket noi'), findsOneWidget);
  });
}
