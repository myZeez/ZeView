import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository/notification_repository.dart';
import '../../util/formatters.dart';
import '../../widgets/app_icon.dart';
import '../app_history/sender_list_screen.dart';
import '../missed/missed_screen.dart';
import '../settings/settings_screen.dart';
import '../whatsapp_deleted/whatsapp_deleted_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NotificationRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeView'),
        actions: [
          IconButton(
            tooltip: 'Terlewat / dihapus',
            icon: const Icon(Icons.history_toggle_off),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MissedScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Pesan WhatsApp terhapus',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WhatsappDeletedScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: repo.refreshNow,
        child: _buildBody(context, repo),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationRepository repo) {
    if (repo.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (repo.appSummaries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 64),
          SizedBox(height: 16),
          Text(
            'Belum ada notifikasi yang terekam.\nBiarkan ZeView berjalan di latar belakang, '
            'notifikasi baru akan muncul di sini.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: repo.appSummaries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final app = repo.appSummaries[index];
        return ListTile(
          leading: AppIcon(iconPath: app.iconPath, label: app.appLabel),
          title: Text(app.appLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            app.lastText?.trim().isNotEmpty == true ? app.lastText!.trim() : app.packageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRelative(app.lastEventTime), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              CircleAvatar(radius: 11, child: Text('${app.totalCount}', style: const TextStyle(fontSize: 11))),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SenderListScreen(packageName: app.packageName, appLabel: app.appLabel),
            ),
          ),
        );
      },
    );
  }
}
