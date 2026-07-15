import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/notification_event.dart';

/// Read-only access to the native `notiview_events.db` written by
/// NotiListenerService (Kotlin). This class must never write to that file —
/// Flutter and the native listener share it concurrently via WAL, with the
/// native side as the sole writer.
class EventsReader {
  Database? _db;

  Future<String> _resolveDbPath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, 'notiview_events.db');
  }

  Future<bool> databaseExists() async {
    final path = await _resolveDbPath();
    return File(path).existsSync();
  }

  Future<Database?> _open() async {
    if (_db != null) return _db;
    if (!await databaseExists()) return null;
    final path = await _resolveDbPath();
    _db = await openDatabase(path, readOnly: true, singleInstance: false);
    return _db;
  }

  Future<List<Map<String, Object?>>> _appSummaryRows() async {
    final db = await _open();
    if (db == null) return [];
    return db.rawQuery('''
      SELECT
        e1.package_name AS package_name,
        MAX(e1.app_label) AS app_label,
        (SELECT icon_path FROM notification_events e2
          WHERE e2.package_name = e1.package_name AND e2.icon_path IS NOT NULL
          ORDER BY e2.device_event_time DESC LIMIT 1) AS icon_path,
        SUM(CASE WHEN e1.event_type = 'POSTED' THEN 1 ELSE 0 END) AS total_count,
        MAX(e1.device_event_time) AS last_time,
        (SELECT COALESCE(big_text, body) FROM notification_events e3
          WHERE e3.package_name = e1.package_name
          ORDER BY e3.device_event_time DESC LIMIT 1) AS last_text
      FROM notification_events e1
      GROUP BY e1.package_name
      ORDER BY last_time DESC
    ''');
  }

  Future<List<AppSummary>> fetchAppSummaries() async {
    final rows = await _appSummaryRows();
    return rows.map(AppSummary.fromMap).toList();
  }

  /// Groups one app's notifications by sender/subject (EXTRA_TITLE), which
  /// is the field most Android apps use for "who/what this is about" —
  /// the contact name in WhatsApp, the sender in Gmail, etc. Notifications
  /// with no title fall into a single "(Tanpa judul)" bucket.
  Future<List<SenderSummary>> fetchSenderSummaries(String packageName) async {
    final db = await _open();
    if (db == null) return [];
    final rows = await db.rawQuery('''
      SELECT
        e1.package_name AS package_name,
        COALESCE(NULLIF(e1.title, ''), '(Tanpa judul)') AS sender_title,
        (SELECT icon_path FROM notification_events e2
          WHERE e2.package_name = e1.package_name AND e2.icon_path IS NOT NULL
          ORDER BY e2.device_event_time DESC LIMIT 1) AS icon_path,
        SUM(CASE WHEN e1.event_type = 'POSTED' THEN 1 ELSE 0 END) AS total_count,
        MAX(e1.device_event_time) AS last_time,
        (SELECT COALESCE(big_text, body) FROM notification_events e3
          WHERE e3.package_name = e1.package_name
            AND COALESCE(NULLIF(e3.title, ''), '(Tanpa judul)') = COALESCE(NULLIF(e1.title, ''), '(Tanpa judul)')
          ORDER BY e3.device_event_time DESC LIMIT 1) AS last_text
      FROM notification_events e1
      WHERE e1.package_name = ?
      GROUP BY sender_title
      ORDER BY last_time DESC
    ''', [packageName]);
    return rows.map(SenderSummary.fromMap).toList();
  }

  Future<List<NotificationEvent>> fetchEventsForSender(
    String packageName,
    String senderTitle, {
    int limit = 300,
    int offset = 0,
  }) async {
    final db = await _open();
    if (db == null) return [];
    final rows = await db.rawQuery('''
      SELECT * FROM notification_events
      WHERE package_name = ? AND COALESCE(NULLIF(title, ''), '(Tanpa judul)') = ?
      ORDER BY device_event_time DESC
      LIMIT ? OFFSET ?
    ''', [packageName, senderTitle, limit, offset]);
    return rows.map(NotificationEvent.fromMap).toList();
  }

  Future<List<NotificationEvent>> fetchEventsForPackage(String packageName, {int limit = 300, int offset = 0}) async {
    final db = await _open();
    if (db == null) return [];
    final rows = await db.query(
      'notification_events',
      where: 'package_name = ?',
      whereArgs: [packageName],
      orderBy: 'device_event_time DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(NotificationEvent.fromMap).toList();
  }

  Future<List<NotificationEvent>> fetchEventsForPackages(List<String> packageNames) async {
    final db = await _open();
    if (db == null || packageNames.isEmpty) return [];
    final placeholders = List.filled(packageNames.length, '?').join(',');
    final rows = await db.query(
      'notification_events',
      where: 'package_name IN ($placeholders)',
      whereArgs: packageNames,
      orderBy: 'device_event_time ASC',
    );
    return rows.map(NotificationEvent.fromMap).toList();
  }

  /// Chains whose most recent event is REMOVED — i.e. no longer visible in
  /// the system tray, whether the user dismissed them, the source app
  /// auto-cleared them, or they were otherwise lost.
  Future<List<NotificationEvent>> fetchMissed({int limit = 300}) async {
    final db = await _open();
    if (db == null) return [];
    final rows = await db.rawQuery('''
      SELECT e1.* FROM notification_events e1
      WHERE e1.event_type = 'REMOVED'
        AND e1.event_id = (SELECT MAX(e2.event_id) FROM notification_events e2 WHERE e2.chain_id = e1.chain_id)
      ORDER BY e1.device_event_time DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(NotificationEvent.fromMap).toList();
  }

  Future<DateTime?> fetchLastCapturedTime() async {
    final db = await _open();
    if (db == null) return null;
    final rows = await db.rawQuery('SELECT MAX(device_event_time) AS t FROM notification_events');
    final t = rows.first['t'] as int?;
    return t != null ? DateTime.fromMillisecondsSinceEpoch(t) : null;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class AppSummary {
  final String packageName;
  final String appLabel;
  final String? iconPath;
  final int totalCount;
  final DateTime lastEventTime;
  final String? lastText;

  AppSummary({
    required this.packageName,
    required this.appLabel,
    required this.iconPath,
    required this.totalCount,
    required this.lastEventTime,
    required this.lastText,
  });

  factory AppSummary.fromMap(Map<String, Object?> map) {
    return AppSummary(
      packageName: map['package_name'] as String,
      appLabel: (map['app_label'] as String?) ?? (map['package_name'] as String),
      iconPath: map['icon_path'] as String?,
      totalCount: (map['total_count'] as int?) ?? 0,
      lastEventTime: DateTime.fromMillisecondsSinceEpoch(map['last_time'] as int),
      lastText: map['last_text'] as String?,
    );
  }
}

/// One sender/subject bucket within a single app (e.g. a WhatsApp contact).
class SenderSummary {
  final String packageName;
  final String senderTitle;
  final String? iconPath;
  final int totalCount;
  final DateTime lastEventTime;
  final String? lastText;

  SenderSummary({
    required this.packageName,
    required this.senderTitle,
    required this.iconPath,
    required this.totalCount,
    required this.lastEventTime,
    required this.lastText,
  });

  factory SenderSummary.fromMap(Map<String, Object?> map) {
    return SenderSummary(
      packageName: map['package_name'] as String,
      senderTitle: map['sender_title'] as String,
      iconPath: map['icon_path'] as String?,
      totalCount: (map['total_count'] as int?) ?? 0,
      lastEventTime: DateTime.fromMillisecondsSinceEpoch(map['last_time'] as int),
      lastText: map['last_text'] as String?,
    );
  }
}
