import 'notification_event.dart';

/// The full lifecycle (POSTED -> UPDATED* -> REMOVED?) of a single
/// real-world notification, grouped by chain_id and ordered oldest-first.
class NotificationChain {
  final String chainId;
  final String packageName;
  final String appLabel;
  final String? iconPath;
  final List<NotificationEvent> events;

  NotificationChain({
    required this.chainId,
    required this.packageName,
    required this.appLabel,
    required this.iconPath,
    required this.events,
  });

  NotificationEvent get latest => events.last;
  NotificationEvent get first => events.first;
  bool get isRemoved => events.last.eventType == 'REMOVED';
  DateTime get lastEventTime => events.last.deviceEventTime;
}

List<NotificationChain> groupIntoChains(List<NotificationEvent> events) {
  final byChain = <String, List<NotificationEvent>>{};
  for (final e in events) {
    byChain.putIfAbsent(e.chainId, () => []).add(e);
  }
  final chains = <NotificationChain>[];
  byChain.forEach((chainId, chainEvents) {
    chainEvents.sort((a, b) => a.deviceEventTime.compareTo(b.deviceEventTime));
    final first = chainEvents.first;
    final iconEvent = chainEvents.lastWhere((e) => e.iconPath != null, orElse: () => first);
    chains.add(NotificationChain(
      chainId: chainId,
      packageName: first.packageName,
      appLabel: first.appLabel,
      iconPath: iconEvent.iconPath,
      events: chainEvents,
    ));
  });
  chains.sort((a, b) => b.lastEventTime.compareTo(a.lastEventTime));
  return chains;
}

/// A WhatsApp/messaging notification whose content was captured before the
/// sender deleted it. This is a heuristic (text-pattern + wording match),
/// not a guaranteed API contract — WhatsApp could change its wording.
class RecoveredDeletedMessage {
  final NotificationChain chain;
  final NotificationEvent originalEvent;
  final NotificationEvent deletionEvent;

  RecoveredDeletedMessage({
    required this.chain,
    required this.originalEvent,
    required this.deletionEvent,
  });
}

const _deletionMarkers = [
  'this message was deleted',
  'you deleted this message',
  'pesan ini telah dihapus',
  'anda menghapus pesan ini',
];

bool _looksLikeDeletionNotice(String text) {
  final lower = text.toLowerCase();
  return _deletionMarkers.any(lower.contains);
}

/// Scans a chain's ordered events for a transition from real content to a
/// "message deleted" notice, and pairs each deletion notice with the last
/// real content that preceded it.
List<RecoveredDeletedMessage> findDeletedMessages(NotificationChain chain) {
  final results = <RecoveredDeletedMessage>[];
  NotificationEvent? lastRealContentEvent;
  for (final event in chain.events) {
    final text = event.displayText;
    if (text.trim().isEmpty) continue;
    if (_looksLikeDeletionNotice(text)) {
      if (lastRealContentEvent != null) {
        results.add(RecoveredDeletedMessage(
          chain: chain,
          originalEvent: lastRealContentEvent,
          deletionEvent: event,
        ));
      }
    } else {
      lastRealContentEvent = event;
    }
  }
  return results;
}
