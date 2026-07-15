/// One immutable row from the native `notification_events` log.
/// A single real-world notification produces one POSTED row, zero or more
/// UPDATED rows, and at most one REMOVED row, all sharing [chainId].
class NotificationEvent {
  final int eventId;
  final String chainId;
  final String? notificationKey;
  final String? groupKey;
  final String packageName;
  final String appLabel;
  final String eventType; // POSTED | UPDATED | REMOVED
  final DateTime deviceEventTime;
  final DateTime? sbnPostTime;
  final String? title;
  final String? body;
  final String? bigText;
  final String? subText;
  final String? conversationTitle;
  final String? messagingStyleJson;
  final String? iconPath;
  final bool isOngoing;
  final String? category;
  final int? removalReason;

  const NotificationEvent({
    required this.eventId,
    required this.chainId,
    required this.notificationKey,
    required this.groupKey,
    required this.packageName,
    required this.appLabel,
    required this.eventType,
    required this.deviceEventTime,
    required this.sbnPostTime,
    required this.title,
    required this.body,
    required this.bigText,
    required this.subText,
    required this.conversationTitle,
    required this.messagingStyleJson,
    required this.iconPath,
    required this.isOngoing,
    required this.category,
    required this.removalReason,
  });

  factory NotificationEvent.fromMap(Map<String, Object?> map) {
    return NotificationEvent(
      eventId: map['event_id'] as int,
      chainId: map['chain_id'] as String,
      notificationKey: map['notification_key'] as String?,
      groupKey: map['group_key'] as String?,
      packageName: map['package_name'] as String,
      appLabel:
          (map['app_label'] as String?) ?? (map['package_name'] as String),
      eventType: map['event_type'] as String,
      deviceEventTime: DateTime.fromMillisecondsSinceEpoch(
        map['device_event_time'] as int,
      ),
      sbnPostTime: map['sbn_post_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['sbn_post_time'] as int)
          : null,
      title: map['title'] as String?,
      body: map['body'] as String?,
      bigText: map['big_text'] as String?,
      subText: map['sub_text'] as String?,
      conversationTitle: map['conversation_title'] as String?,
      messagingStyleJson: map['messaging_style_json'] as String?,
      iconPath: map['icon_path'] as String?,
      isOngoing: (map['is_ongoing'] as int?) == 1,
      category: map['category'] as String?,
      removalReason: map['removal_reason'] as int?,
    );
  }

  /// Best available text for this event: prefers the expanded body over the
  /// collapsed one since messaging/email apps often put the fuller content there.
  String get displayText =>
      (bigText != null && bigText!.trim().isNotEmpty) ? bigText! : (body ?? '');
}

/// Android NotificationListenerService.REASON_* codes we bother to label.
String removalReasonLabel(int? reason) {
  switch (reason) {
    case 1:
      return 'Dibuka';
    case 2:
    case 3:
      return 'Dihapus dari tray';
    case 8:
    case 9:
      return 'Ditutup otomatis oleh aplikasi';
    case 10:
    case 11:
      return 'Ditutup oleh Zeview';
    case 18:
      return 'Ditunda (snooze)';
    case 19:
      return 'Kedaluwarsa (timeout)';
    default:
      return 'Sudah tidak ada di tray';
  }
}
