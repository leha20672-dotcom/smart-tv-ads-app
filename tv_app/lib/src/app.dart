import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/application/auth_provider.dart';
import 'features/device/presentation/device_register_screen.dart';
import 'features/player/presentation/player_screen.dart';

class SmartTvAdsApp extends ConsumerWidget {
  const SmartTvAdsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeStateAsync = ref.watch(appRouteStateProvider);

    return MaterialApp(
      title: 'Smart TV Ads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: routeStateAsync.when(
        loading: () => const _SplashScreen(),
        error: (error, stackTrace) => const DeviceRegisterScreen(),
        data: (routeState) {
          if (!routeState.canPlay) {
            return const DeviceRegisterScreen();
          }

          return PlayerScreen(deviceId: routeState.deviceId!);
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
