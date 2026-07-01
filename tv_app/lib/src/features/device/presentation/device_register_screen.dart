import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../application/device_provider.dart';
import '../domain/device.dart';
import 'widgets/app_logo_header.dart';

enum _PairingStep { inputName, waitingApproval }

class DeviceRegisterScreen extends ConsumerStatefulWidget {
  const DeviceRegisterScreen({super.key});

  @override
  ConsumerState<DeviceRegisterScreen> createState() =>
      _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends ConsumerState<DeviceRegisterScreen> {
  final TextEditingController _deviceNameController = TextEditingController();

  _PairingStep _step = _PairingStep.inputName;
  String? _deviceCode;
  String? _status;
  String? _errorText;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isPolling = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoredDevice();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredDevice() async {
    final repository = ref.read(deviceRepositoryProvider);
    final token = await repository.getDeviceToken();
    final deviceCode = await repository.getDeviceCode();
    final status = await repository.getDeviceStatus();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      ref.invalidate(appRouteStateProvider);
      return;
    }

    setState(() {
      _deviceCode = deviceCode;
      _status = status;
      _isInitializing = false;
      _step = deviceCode == null || deviceCode.isEmpty
          ? _PairingStep.inputName
          : _PairingStep.waitingApproval;
    });

    if (deviceCode != null && deviceCode.isNotEmpty) {
      _startPairingPolling();
    }
  }

  Future<void> _registerDevice() async {
    final name = _deviceNameController.text.trim();

    if (name.isEmpty) {
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
      final registration = await ref
          .read(deviceRepositoryProvider)
          .registerDevice(name: name, deviceCode: _deviceCode);

      if (!mounted) return;

      setState(() {
        _deviceCode = registration.deviceCode;
        _status = registration.status;
        _step = _PairingStep.waitingApproval;
      });

      ref.invalidate(deviceCodeProvider);
      ref.invalidate(deviceStatusProvider);

      if (registration.deviceToken?.isNotEmpty == true) {
        _pollingTimer?.cancel();
        ref.invalidate(deviceTokenProvider);
        ref.invalidate(appRouteStateProvider);
        return;
      }

      _startPairingPolling();
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText = _deviceErrorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startPairingPolling() {
    _pollingTimer?.cancel();
    _checkPairing();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPairing();
    });
  }

  Future<void> _checkPairing() async {
    if (_isPolling) return;

    _isPolling = true;

    try {
      final pairingStatus = await ref
          .read(deviceRepositoryProvider)
          .checkPairing();

      if (!mounted) return;

      setState(() {
        _status = pairingStatus.status;
        _errorText = pairingStatus.isActive ? null : pairingStatus.message;
      });

      ref.invalidate(deviceStatusProvider);

      if (pairingStatus.isActive) {
        _pollingTimer?.cancel();
        ref.invalidate(deviceTokenProvider);
        ref.invalidate(appRouteStateProvider);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText = _deviceErrorMessage(error);
        });
      }
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _resetDevice() async {
    _pollingTimer?.cancel();

    await ref.read(deviceRepositoryProvider).clearDevice();

    if (!mounted) return;

    setState(() {
      _deviceCode = null;
      _status = null;
      _errorText = null;
      _step = _PairingStep.inputName;
    });

    ref.invalidate(deviceCodeProvider);
    ref.invalidate(deviceStatusProvider);
    ref.invalidate(deviceTokenProvider);
    ref.invalidate(appRouteStateProvider);
  }

  String _deviceErrorMessage(Object error) {
    if (error is ApiException) {
      if (_isDeviceSchemaMismatch(error.message)) {
        return 'Database API chưa cập nhật schema mới: thiếu cột device_code trong bảng devices. Hãy chạy migration/cập nhật database Laravel rồi thử lại.';
      }

      return error.message;
    }

    return 'Không thể kết nối API. Kiểm tra địa chỉ server hoặc mạng.';
  }

  bool _isDeviceSchemaMismatch(String message) {
    final normalizedMessage = message.toLowerCase();

    return normalizedMessage.contains('sqlstate') &&
        normalizedMessage.contains('unknown column') &&
        normalizedMessage.contains('device_code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;
            final horizontalPadding = isCompact ? 20.0 : 48.0;
            final cardPadding = EdgeInsets.symmetric(
              horizontal: isCompact ? 24 : 72,
              vertical: isCompact ? 32 : 56,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                32,
                horizontalPadding,
                32 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 64
                      ? constraints.maxHeight - 64
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 770),
                    child: Container(
                      width: double.infinity,
                      padding: cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.panel,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.panelBorder),
                      ),
                      child: _isInitializing
                          ? const SizedBox(
                              height: 320,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _buildContent(),
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

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogoHeader(titleColor: AppColors.onDark),
        const SizedBox(height: 20),
        Text(
          _step == _PairingStep.inputName
              ? 'Đăng ký thiết bị'
              : 'Chờ Admin duyệt',
          style: const TextStyle(
            color: AppColors.onDark,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _step == _PairingStep.inputName
              ? 'Nhập tên thiết bị để đăng ký TV.'
              : 'Yêu cầu đã được gửi. Duyệt mã này trên Web Admin để kích hoạt TV.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        if (_step == _PairingStep.inputName) _buildRegisterForm(),
        if (_step == _PairingStep.waitingApproval) _buildPairingStatus(),
        if (_errorText != null) ...[
          const SizedBox(height: 18),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _deviceNameController,
          cursorColor: AppColors.primary,
          textAlign: TextAlign.center,
          enabled: !_isLoading,
          onSubmitted: (_) {
            if (!_isLoading) {
              _registerDevice();
            }
          },
          style: const TextStyle(
            fontSize: 22,
            color: AppColors.onDark,
            fontWeight: FontWeight.bold,
          ),
          decoration: _inputDecoration('Tên thiết bị'),
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Gửi yêu cầu đăng ký',
          loadingLabel: 'Đang gửi yêu cầu...',
          onPressed: _registerDevice,
        ),
      ],
    );
  }

  Widget _buildPairingStatus() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            children: [
              Text(
                'Mã thiết bị',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                _deviceCode ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onDark,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _status == DeviceStatus.active
                        ? 'Đã kích hoạt'
                        : 'Đang chờ Admin duyệt',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _primaryButton(label: 'Kiểm tra lại', onPressed: _checkPairing),
        const SizedBox(height: 18),
        TextButton(
          onPressed: _isLoading ? null : _resetDevice,
          child: const Text('Đăng ký lại'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
      ),
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
    String? loadingLabel,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  if (loadingLabel != null) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        loadingLabel,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
