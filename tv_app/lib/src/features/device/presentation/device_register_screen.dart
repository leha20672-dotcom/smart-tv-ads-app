import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_provider.dart';
import '../application/device_provider.dart';
import '../domain/device.dart';
import 'widgets/app_logo_header.dart';

enum _RegisterStep { login, createDevice, waitingApproval }

class DeviceRegisterScreen extends ConsumerStatefulWidget {
  const DeviceRegisterScreen({super.key});

  @override
  ConsumerState<DeviceRegisterScreen> createState() =>
      _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends ConsumerState<DeviceRegisterScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'admin@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController(
    text: 'TV Sảnh Chính',
  );

  _RegisterStep _step = _RegisterStep.login;
  String? _authToken;
  int? _deviceId;
  String? _deviceCode;
  String? _deviceStatus;
  String? _errorText;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isPollingStatus = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoredState();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredState() async {
    final authRepository = ref.read(authRepositoryProvider);
    final deviceRepository = ref.read(deviceRepositoryProvider);

    final token = await authRepository.getToken();
    final deviceId = await deviceRepository.getDeviceId();
    final deviceCode = await deviceRepository.getDeviceCode();
    final deviceStatus = await deviceRepository.getDeviceStatus();

    if (!mounted) return;

    setState(() {
      _authToken = token;
      _deviceId = deviceId;
      _deviceCode = deviceCode;
      _deviceStatus = deviceStatus;
      _isInitializing = false;
      _step = _resolveStep(token: token, deviceId: deviceId);
    });

    if (token != null && token.isNotEmpty && deviceId != null) {
      _startStatusPolling();
    }
  }

  _RegisterStep _resolveStep({required String? token, required int? deviceId}) {
    if (token == null || token.isEmpty) {
      return _RegisterStep.login;
    }

    if (deviceId == null) {
      return _RegisterStep.createDevice;
    }

    return _RegisterStep.waitingApproval;
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập email và mật khẩu';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      if (!mounted) return;

      setState(() {
        _authToken = session.token;
        _step = _RegisterStep.createDevice;
      });

      ref.invalidate(authTokenProvider);
      ref.invalidate(authUserProvider);
      ref.invalidate(appRouteStateProvider);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText = _loginErrorMessage(error);
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

  String _loginErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Email hoặc mật khẩu không đúng';
      }

      if (error.statusCode == 500) {
        return 'API đang lỗi server (500). Kiểm tra cấu hình database Laravel.';
      }

      return 'Không thể đăng nhập: ${error.message}';
    }

    return 'Không thể kết nối API. Kiểm tra địa chỉ server hoặc mạng.';
  }

  Future<void> _createDevice() async {
    final token = _authToken;
    final deviceName = _deviceNameController.text.trim();

    if (token == null || token.isEmpty) {
      setState(() {
        _step = _RegisterStep.login;
        _errorText = 'Phiên đăng nhập đã hết hạn';
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
      final device = await ref
          .read(deviceRepositoryProvider)
          .createDevice(
            authToken: token,
            name: deviceName,
            type: 'android_box',
          );

      if (!mounted) return;

      setState(() {
        _deviceId = device.id;
        _deviceCode = device.deviceCode;
        _deviceStatus = device.status;
        _step = _RegisterStep.waitingApproval;
      });

      ref.invalidate(deviceIdProvider);
      ref.invalidate(deviceCodeProvider);
      ref.invalidate(deviceStatusProvider);
      ref.invalidate(appRouteStateProvider);

      if (DeviceStatus.isActive(device.status)) {
        _openPlayerWhenReady();
      } else {
        _startStatusPolling();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Không thể tạo thiết bị. Vui lòng kiểm tra API.';
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

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _pollDeviceStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollDeviceStatus();
    });
  }

  Future<void> _pollDeviceStatus() async {
    if (_isPollingStatus) return;

    final token = _authToken;
    final deviceId = _deviceId;

    if (token == null || token.isEmpty || deviceId == null) {
      return;
    }

    _isPollingStatus = true;

    try {
      final status = await ref
          .read(deviceRepositoryProvider)
          .refreshDeviceStatus(deviceId: deviceId, authToken: token);

      if (!mounted) return;

      setState(() {
        _deviceStatus = status;
        _errorText = null;
      });

      ref.invalidate(deviceStatusProvider);

      if (DeviceStatus.isActive(status)) {
        _openPlayerWhenReady();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Đang chờ Web Admin xác nhận thiết bị...';
        });
      }
    } finally {
      _isPollingStatus = false;
    }
  }

  void _openPlayerWhenReady() {
    _statusTimer?.cancel();
    ref.invalidate(appRouteStateProvider);
  }

  Future<void> _logout() async {
    _statusTimer?.cancel();

    await ref.read(authRepositoryProvider).logout();
    await ref.read(deviceRepositoryProvider).clearDevice();

    if (!mounted) return;

    setState(() {
      _authToken = null;
      _deviceId = null;
      _deviceCode = null;
      _deviceStatus = null;
      _errorText = null;
      _step = _RegisterStep.login;
    });

    ref.invalidate(authTokenProvider);
    ref.invalidate(authUserProvider);
    ref.invalidate(deviceIdProvider);
    ref.invalidate(deviceCodeProvider);
    ref.invalidate(deviceStatusProvider);
    ref.invalidate(appRouteStateProvider);
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
                    width: 520,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _isInitializing
                          ? const Center(child: CircularProgressIndicator())
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
        const AppLogoHeader(),
        const SizedBox(height: 20),
        _buildTitle(),
        const SizedBox(height: 12),
        _buildSubtitle(),
        const SizedBox(height: 32),
        if (_step == _RegisterStep.login) _buildLoginForm(),
        if (_step == _RegisterStep.createDevice) _buildDeviceForm(),
        if (_step == _RegisterStep.waitingApproval) _buildWaitingApproval(),
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

  Widget _buildTitle() {
    final title = switch (_step) {
      _RegisterStep.login => 'Đăng nhập',
      _RegisterStep.createDevice => 'Tạo thiết bị',
      _RegisterStep.waitingApproval => 'Chờ xác nhận',
    };

    return Text(
      title,
      style: const TextStyle(
        color: AppColors.title,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle() {
    final text = switch (_step) {
      _RegisterStep.login => 'Đăng nhập để tạo thiết bị và nhận lịch phát.',
      _RegisterStep.createDevice =>
        'Nhập tên TV/Android Box để server tạo mã thiết bị.',
      _RegisterStep.waitingApproval =>
        'Web Admin xác nhận xong thì TV sẽ tự chuyển sang phát quảng cáo.',
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18, color: Colors.grey.shade500, height: 1.4),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 20, color: AppColors.title),
          decoration: _inputDecoration('Email'),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: true,
          onSubmitted: (_) {
            if (!_isLoading) {
              _login();
            }
          },
          style: const TextStyle(fontSize: 20, color: AppColors.title),
          decoration: _inputDecoration('Mật khẩu'),
        ),
        const SizedBox(height: 28),
        _primaryButton(label: 'Đăng nhập', onPressed: _login),
      ],
    );
  }

  Widget _buildDeviceForm() {
    return Column(
      children: [
        TextField(
          controller: _deviceNameController,
          textAlign: TextAlign.center,
          enabled: !_isLoading,
          onSubmitted: (_) {
            if (!_isLoading) {
              _createDevice();
            }
          },
          style: const TextStyle(
            fontSize: 22,
            color: AppColors.title,
            fontWeight: FontWeight.bold,
          ),
          decoration: _inputDecoration('Tên thiết bị'),
        ),
        const SizedBox(height: 28),
        _primaryButton(label: 'Tạo mã thiết bị', onPressed: _createDevice),
        const SizedBox(height: 18),
        TextButton(
          onPressed: _isLoading ? null : _logout,
          child: const Text('Đăng xuất'),
        ),
      ],
    );
  }

  Widget _buildWaitingApproval() {
    final deviceCode =
        _deviceCode ?? (_deviceId == null ? '' : 'TV-$_deviceId');
    final status = _deviceStatus ?? DeviceStatus.pending;
    final isActive = DeviceStatus.isActive(status);

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
                deviceCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.title,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isActive)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!isActive) const SizedBox(width: 12),
                  Text(
                    isActive ? 'Đã xác nhận' : 'Đang chờ xác nhận',
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.white70,
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
        _primaryButton(
          label: 'Kiểm tra trạng thái',
          onPressed: _pollDeviceStatus,
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: _isLoading ? null : _logout,
          child: const Text('Đăng xuất'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 18),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade400),
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
            ? const CircularProgressIndicator()
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
