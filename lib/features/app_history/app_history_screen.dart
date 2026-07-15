import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_event.dart';
import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';

class AppHistoryScreen extends StatefulWidget {
  final String packageName;
  final String appLabel;
  /// When set, restricts the log to notifications from this sender/subject
  /// (EXTRA_TITLE) within the app — e.g. one WhatsApp contact.
  final String? senderTitle;

  const AppHistoryScreen({super.key, required this.packageName, required this.appLabel, this.senderTitle});

  @override
  State<AppHistoryScreen> createState() => _AppHistoryScreenState();
}

class _AppHistoryScreenState extends State<AppHistoryScreen> {
  final List<NotificationEvent> _events = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  static const _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<List<NotificationEvent>> _fetch({required int limit, required int offset}) {
    final repo = context.read<NotificationRepository>();
    final sender = widget.senderTitle;
    return sender != null
        ? repo.fetchHistoryForSender(widget.packageName, sender, limit: limit, offset: offset)
        : repo.fetchHistoryForPackage(widget.packageName, limit: limit, offset: offset);
  }

  Future<void> _loadInitial() async {
    final events = await _fetch(limit: _pageSize, offset: 0);
    if (!mounted) return;
    setState(() {
      _events
        ..clear()
        ..addAll(events);
      _loading = false;
      _hasMore = events.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final more = await _fetch(limit: _pageSize, offset: _events.length);
    if (!mounted) return;
    setState(() {
      _events.addAll(more);
      _loadingMore = false;
      _hasMore = more.length == _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.senderTitle != null ? '${widget.appLabel} — ${widget.senderTitle}' : widget.appLabel;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('Belum ada riwayat.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll.metrics.pixels > scroll.metrics.maxScrollExtent - 200) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _events.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= _events.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return _EventCard(event: _events[index]);
                    },
                  ),
                ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final NotificationEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (event.eventType) {
      'POSTED' => ('Baru masuk', Colors.green),
      'UPDATED' => ('Diperbarui', Colors.blue),
      'REMOVED' => ('Hilang dari tray', Colors.orange),
      _ => (event.eventType, Colors.grey),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(formatExactDateTime(event.deviceEventTime), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (event.title?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(event.title!, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            if (event.displayText.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(event.displayText),
            ],
          ],
        ),
      ),
    );
  }
}
