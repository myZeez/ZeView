import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/events_reader.dart';
import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';
import '../../widgets/app_icon.dart';
import 'app_history_screen.dart';

/// Shown after tapping an app on Home: breaks that app's notifications down
/// by sender/subject (e.g. each WhatsApp contact) before drilling into the
/// full chronological log.
class SenderListScreen extends StatefulWidget {
  final String packageName;
  final String appLabel;

  const SenderListScreen({super.key, required this.packageName, required this.appLabel});

  @override
  State<SenderListScreen> createState() => _SenderListScreenState();
}

class _SenderListScreenState extends State<SenderListScreen> {
  List<SenderSummary>? _senders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<NotificationRepository>();
    final senders = await repo.fetchSendersForPackage(widget.packageName);
    if (!mounted) return;
    setState(() => _senders = senders);
  }

  @override
  Widget build(BuildContext context) {
    final senders = _senders;
    return Scaffold(
      appBar: AppBar(title: Text(widget.appLabel)),
      body: senders == null
          ? const Center(child: CircularProgressIndicator())
          : senders.isEmpty
              ? const Center(child: Text('Belum ada riwayat.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: senders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = senders[index];
                      return ListTile(
                        leading: AppIcon(iconPath: s.iconPath, label: s.senderTitle),
                        title: Text(s.senderTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          s.lastText?.trim().isNotEmpty == true ? s.lastText!.trim() : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatRelative(s.lastEventTime), style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            CircleAvatar(radius: 11, child: Text('${s.totalCount}', style: const TextStyle(fontSize: 11))),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AppHistoryScreen(
                              packageName: widget.packageName,
                              appLabel: widget.appLabel,
                              senderTitle: s.senderTitle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
