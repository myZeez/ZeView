import 'dart:async';

import 'package:flutter/foundation.dart';

import '../db/events_reader.dart';
import '../models/notification_chain.dart';
import '../models/notification_event.dart';

class NotificationRepository extends ChangeNotifier {
  final EventsReader _reader = EventsReader();
  Timer? _pollTimer;

  bool isLoading = true;
  bool hasAnyData = false;
  List<AppSummary> appSummaries = const [];
  DateTime? lastCapturedTime;

  void startPolling({Duration interval = const Duration(seconds: 3)}) {
    unawaited(_refresh());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _refresh());
  }

  Future<void> refreshNow() => _refresh();

  Future<void> _refresh() async {
    final exists = await _reader.databaseExists();
    final summaries = await _reader.fetchAppSummaries();
    final lastCaptured = await _reader.fetchLastCapturedTime();
    hasAnyData = exists;
    appSummaries = summaries;
    lastCapturedTime = lastCaptured;
    isLoading = false;
    notifyListeners();
  }

  Future<List<NotificationEvent>> fetchHistoryForPackage(String packageName, {int limit = 300, int offset = 0}) =>
      _reader.fetchEventsForPackage(packageName, limit: limit, offset: offset);

  Future<List<SenderSummary>> fetchSendersForPackage(String packageName) =>
      _reader.fetchSenderSummaries(packageName);

  Future<List<NotificationEvent>> fetchHistoryForSender(String packageName, String senderTitle,
          {int limit = 300, int offset = 0}) =>
      _reader.fetchEventsForSender(packageName, senderTitle, limit: limit, offset: offset);

  Future<List<NotificationEvent>> fetchMissed({int limit = 300}) => _reader.fetchMissed(limit: limit);

  Future<List<RecoveredDeletedMessage>> fetchWhatsappDeletedMessages() async {
    final events = await _reader.fetchEventsForPackages(const ['com.whatsapp', 'com.whatsapp.w4b']);
    final chains = groupIntoChains(events);
    final results = <RecoveredDeletedMessage>[];
    for (final chain in chains) {
      results.addAll(findDeletedMessages(chain));
    }
    results.sort((a, b) => b.deletionEvent.deviceEventTime.compareTo(a.deletionEvent.deviceEventTime));
    return results;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    unawaited(_reader.close());
    super.dispose();
  }
}
