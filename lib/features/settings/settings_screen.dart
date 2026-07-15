import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/native/native_bridge.dart';
import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _listenerEnabled;
  bool? _batteryExempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final listener = await NativeBridge.isListenerEnabled();
    final battery = await NativeBridge.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _listenerEnabled = listener;
      _batteryExempt = battery;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NotificationRepository>();
    final lastCaptured = repo.lastCapturedTime;
    final isStale =
        lastCaptured != null &&
        DateTime.now().difference(lastCaptured) > const Duration(hours: 6);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Akses Notifikasi'),
            subtitle: Text(
              _listenerEnabled == true
                  ? 'Aktif'
                  : 'Belum aktif — wajib untuk merekam notifikasi',
            ),
            value: _listenerEnabled ?? false,
            onChanged: (_) => NativeBridge.openListenerSettings(),
          ),
          SwitchListTile(
            title: const Text('Bebas Optimasi Baterai'),
            subtitle: Text(
              _batteryExempt == true
                  ? 'Aktif — lebih tahan dari sistem mematikan aplikasi'
                  : 'Nonaktif — sistem berpotensi mematikan perekaman di latar belakang',
            ),
            value: _batteryExempt ?? false,
            onChanged: (_) => NativeBridge.openBatteryOptimizationSettings(),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isStale
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: isStale ? Colors.orange : Colors.green,
            ),
            title: const Text('Notifikasi terakhir direkam'),
            subtitle: Text(
              lastCaptured != null
                  ? '${formatExactDateTime(lastCaptured)}${isStale ? '\nSudah lama tidak ada notifikasi baru — periksa apakah perekaman masih berjalan.' : ''}'
                  : 'Belum ada data',
            ),
            isThreeLine: isStale,
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sambungkan ulang layanan perekaman'),
            subtitle: const Text(
              'Gunakan jika perekaman berhenti tanpa alasan jelas',
            ),
            onTap: () async {
              final ok = await NativeBridge.requestRebind();
              await NativeBridge.startForegroundService();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Berhasil meminta sambung ulang'
                          : 'Gagal meminta sambung ulang',
                    ),
                  ),
                );
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Catatan: jika HP kamu bermerek Xiaomi, Oppo, Vivo, atau sejenisnya, aktifkan juga '
              '"Autostart" / "Mulai otomatis" untuk Zeview di pengaturan baterai bawaan HP, karena '
              'sistem tersebut sering mematikan aplikasi latar belakang secara agresif.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
