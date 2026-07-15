import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_chain.dart';
import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';
import '../../widgets/app_icon.dart';

class WhatsappDeletedScreen extends StatefulWidget {
  const WhatsappDeletedScreen({super.key});

  @override
  State<WhatsappDeletedScreen> createState() => _WhatsappDeletedScreenState();
}

class _WhatsappDeletedScreenState extends State<WhatsappDeletedScreen> {
  List<RecoveredDeletedMessage>? _messages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<NotificationRepository>();
    final messages = await repo.fetchWhatsappDeletedMessages();
    if (!mounted) return;
    setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan WhatsApp Terhapus')),
      body: messages == null
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada pesan yang terdeteksi dihapus pengirim.\n\n'
                      'Deteksi ini berbasis pencocokan kata "pesan ini telah dihapus" dan hanya '
                      'bekerja untuk pesan yang sempat masuk sebagai notifikasi sebelum dihapus.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      return ListTile(
                        leading: AppIcon(iconPath: m.chain.iconPath, label: m.chain.appLabel),
                        title: Text(m.originalEvent.title?.trim().isNotEmpty == true
                            ? m.originalEvent.title!
                            : m.chain.appLabel),
                        subtitle: Text(
                          '"${m.originalEvent.displayText}"\n'
                          'Terkirim: ${formatExactDateTime(m.originalEvent.deviceEventTime)}\n'
                          'Dihapus sekitar: ${formatExactDateTime(m.deletionEvent.deviceEventTime)}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
    );
  }
}
