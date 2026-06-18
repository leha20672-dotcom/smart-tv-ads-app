import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/device_provider.dart';
import 'widgets/app_logo_header.dart';

class DeviceRegisterScreen extends ConsumerStatefulWidget {
  const DeviceRegisterScreen({super.key});

  @override
  ConsumerState<DeviceRegisterScreen> createState() =>
      _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends ConsumerState<DeviceRegisterScreen> {
  final TextEditingController _deviceCodeController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _submitDeviceCode() async {
    final deviceCode = _deviceCodeController.text.trim();
    final deviceName = _deviceNameController.text.trim();

    if (deviceCode.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập mã thiết bị';
      });
      return;
    }

    if (deviceName.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập tên thiết bị';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final repository = ref.read(deviceRepositoryProvider);

      await repository.registerDevice(
        deviceCode: deviceCode,
        name: deviceName,
        orientation: 'landscape',
      );

      ref.invalidate(deviceIdProvider);
      ref.invalidate(deviceCodeProvider);
    } catch (error) {
      setState(() {
        _errorText = 'Không thể đăng ký thiết bị. Kiểm tra API hoặc mã thiết bị.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                            'Đăng ký thiết bị',
                            style: TextStyle(
                              color: AppColors.title,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Nhập mã thiết bị và tên thiết bị để kết nối Android Box / Smart TV với hệ thống quản trị.',
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
                            textAlign: TextAlign.center,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.title,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Mã thiết bị - VD: TV-123456',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
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

                          const SizedBox(height: 18),

                          TextField(
                            controller: _deviceNameController,
                            textAlign: TextAlign.center,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontSize: 22,
                              color: AppColors.title,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tên thiết bị - VD: TV Cổng 1',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
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
                              onPressed: _isLoading ? null : _submitDeviceCode,
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
                                  ? const CircularProgressIndicator()
                                  : const Text('Kích hoạt thiết bị'),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Sau khi kích hoạt, thiết bị sẽ được lưu vào bộ nhớ cục bộ.',
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