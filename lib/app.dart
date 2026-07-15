import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/native/native_bridge.dart';
import 'data/repository/notification_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class NotiViewApp extends StatelessWidget {
  const NotiViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationRepository(),
      child: MaterialApp(
        title: 'Zeview',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final granted = await NativeBridge.isListenerEnabled();
    if (!mounted) return;
    if (granted) {
      context.read<NotificationRepository>().startPolling();
    }
    setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_granted == false) {
      return OnboardingScreen(
        onGranted: () {
          context.read<NotificationRepository>().startPolling();
          setState(() => _granted = true);
        },
      );
    }
    return const HomeScreen();
  }
}
