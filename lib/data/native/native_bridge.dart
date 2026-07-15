import 'package:flutter/services.dart';

/// Thin wrapper over the `noti_view/native` MethodChannel implemented in
/// MainActivity.kt — permission checks/deep-links and service control,
/// since Android exposes none of this to Dart directly.
class NativeBridge {
  static const _channel = MethodChannel('noti_view/native');

  static Future<bool> isListenerEnabled() async =>
      await _channel.invokeMethod<bool>('isListenerEnabled') ?? false;

  static Future<void> openListenerSettings() => _channel.invokeMethod('openListenerSettings');

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  static Future<void> openBatteryOptimizationSettings() =>
      _channel.invokeMethod('openBatteryOptimizationSettings');

  static Future<bool> requestRebind() async =>
      await _channel.invokeMethod<bool>('requestRebind') ?? false;

  static Future<void> startForegroundService() => _channel.invokeMethod('startForegroundService');
}
