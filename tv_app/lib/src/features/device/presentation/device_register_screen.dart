import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_app/src/features/device/application/device_provider.dart'
    as device_providers;

import '../../../core/theme/app_colors.dart';
import 'widgets/app_logo_header.dart';

class DeviceRegisterScreen extends ConsumerStatefulWidget {
  const DeviceRegisterScreen({super.key});

  @override
  ConsumerState<DeviceRegisterScreen> createState() =>
      _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends ConsumerState<DeviceRegisterScreen> {
  final TextEditingController _deviceCodeController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitDeviceCode() async {
    final deviceCode = _deviceCodeController.text.trim();

    if (deviceCode.isEmpty) {
      setState(() {
        _errorText = 'Vui l\u00f2ng nh\u1eadp m\u00e3 thi\u1ebft b\u1ecb';
      });
      return;
    }

    if (deviceCode.length < 4) {
      setState(() {
        _errorText =
            'M\u00e3 thi\u1ebft b\u1ecb kh\u00f4ng h\u1ee3p l\u1ec7';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      await ref.refresh(
        device_providers.activateDeviceProvider(deviceCode).future,
      );
      ref.invalidate(device_providers.deviceTokenProvider);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: SizedBox(
                    width: 500,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogoHeader(),
                          const SizedBox(height: 20),
                          const Text(
                            '\u0110\u0103ng k\u00fd thi\u1ebft b\u1ecb',
                            style: TextStyle(
                              color: AppColors.title,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nh\u1eadp m\u00e3 thi\u1ebft b\u1ecb \u0111\u01b0\u1ee3c cung c\u1ea5p t\u1eeb h\u1ec7 th\u1ed1ng qu\u1ea3n tr\u1ecb \u0111\u1ec3 k\u00edch ho\u1ea1t Android Box / Smart TV.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _deviceCodeController,
                            enabled: !_isLoading,
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _submitDeviceCode();
                              }
                            },
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              color: AppColors.title,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'VD: TV-123456',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 22,
                                letterSpacing: 1,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                              errorText: _errorText,
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _submitDeviceCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'K\u00edch ho\u1ea1t thi\u1ebft b\u1ecb',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'N\u1ebfu ch\u01b0a c\u00f3 m\u00e3, vui l\u00f2ng t\u1ea1o thi\u1ebft b\u1ecb tr\u00ean Web Admin tr\u01b0\u1edbc.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
