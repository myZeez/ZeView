import 'package:flutter/material.dart';

import '../../data/native/native_bridge.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const OnboardingScreen({super.key, required this.onGranted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    setState(() => _checking = true);
    final enabled = await NativeBridge.isListenerEnabled();
    if (!mounted) return;
    setState(() => _checking = false);
    if (enabled) {
      await NativeBridge.startForegroundService();
      widget.onGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.notifications_active_outlined, size: 72),
              const SizedBox(height: 24),
              Text(
                'Selamat datang di Zeview',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Zeview merekam semua notifikasi yang masuk ke HP kamu, dikelompokkan per '
                'aplikasi, lengkap dengan tanggal dan jam yang akurat — termasuk notifikasi yang '
                'sudah kamu hapus atau pesan WhatsApp yang dihapus pengirim sebelum sempat kamu baca.\n\n'
                'Untuk itu, Zeview butuh izin "Notification access" dari sistem Android. '
                'Semua data disimpan lokal di HP kamu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => NativeBridge.openListenerSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan Izin'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _checking ? null : _checkPermission,
                child: _checking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sudah saya aktifkan, cek ulang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
