import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_event.dart';
import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';
import '../../widgets/app_icon.dart';

/// Notifications no longer visible in the system tray — whether the user
/// dismissed them, the source app auto-cleared them, or anything else.
/// Because capture is append-only, the content is never actually lost.
class MissedScreen extends StatefulWidget {
  const MissedScreen({super.key});

  @override
  State<MissedScreen> createState() => _MissedScreenState();
}

class _MissedScreenState extends State<MissedScreen> {
  List<NotificationEvent>? _events;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<NotificationRepository>();
    final events = await repo.fetchMissed();
    if (!mounted) return;
    setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return Scaffold(
      appBar: AppBar(title: const Text('Terlewat / Terhapus')),
      body: events == null
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi yang hilang dari tray.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return ListTile(
                        leading: AppIcon(iconPath: e.iconPath, label: e.appLabel),
                        title: Text(e.title?.trim().isNotEmpty == true ? e.title! : e.appLabel),
                        subtitle: Text(
                          '${e.displayText}\n${removalReasonLabel(e.removalReason)} • ${formatExactDateTime(e.deviceEventTime)}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
    );
  }
}
