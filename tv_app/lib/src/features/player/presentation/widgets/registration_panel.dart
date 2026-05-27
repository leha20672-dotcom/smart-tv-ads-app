import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/player_controller.dart';

class RegistrationPanel extends ConsumerStatefulWidget {
  const RegistrationPanel({
    required this.initialBaseUrl,
    this.message,
    super.key,
  });

  final String initialBaseUrl;
  final String? message;

  @override
  ConsumerState<RegistrationPanel> createState() => _RegistrationPanelState();
}

class _RegistrationPanelState extends ConsumerState<RegistrationPanel> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _deviceCodeController;
  late final TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.initialBaseUrl);
    _deviceCodeController = TextEditingController(text: 'TV-DEMO-01');
    _deviceNameController = TextEditingController(text: 'TV Demo');
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _deviceCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dang ky TV',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Backend URL',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deviceCodeController,
                decoration: const InputDecoration(
                  labelText: 'Device code',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Ten TV',
                  prefixIcon: Icon(Icons.tv),
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xfffca5a5)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(playerControllerProvider.notifier).register(
                        baseUrl: _baseUrlController.text,
                        deviceCode: _deviceCodeController.text,
                        deviceName: _deviceNameController.text,
                      );
                },
                icon: const Icon(Icons.login),
                label: const Text('Dang ky va ket noi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
