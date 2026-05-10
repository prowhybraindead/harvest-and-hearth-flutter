import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().refreshNotificationLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    final summaryBody = t('expiry_notif_summary_body')
        .replaceAll('{expired}', '2')
        .replaceAll('{expiring}', '3');
    final urgentBody =
        t('expiry_notif_urgent_body').replaceAll('{expired}', '2');
    final testBody = t('expiry_notif_test_body')
        .replaceAll('{expired}', '2')
        .replaceAll('{expiring}', '3');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('notif_center_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: t('dashboard_refresh'),
            onPressed: provider.isLoadingNotifications
                ? null
                : () => provider.refreshNotificationLogs(),
            icon: provider.isLoadingNotifications
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          _SectionTitle(title: t('notif_center_status_title')),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                provider.expiryRemindersEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: provider.expiryRemindersEnabled ? cs.primary : cs.error,
              ),
              title: Text(
                provider.expiryRemindersEnabled
                    ? t('notif_center_status_on')
                    : t('notif_center_status_off'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: t('notif_center_copy_title')),
          const SizedBox(height: 8),
          _CopyCard(
            icon: Icons.schedule_rounded,
            title: t('expiry_notif_summary_title'),
            message: summaryBody,
          ),
          const SizedBox(height: 8),
          _CopyCard(
            icon: Icons.priority_high_rounded,
            title: t('expiry_notif_urgent_title'),
            message: urgentBody,
          ),
          const SizedBox(height: 8),
          _CopyCard(
            icon: Icons.science_outlined,
            title: t('expiry_notif_test_title'),
            message: testBody,
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: t('notif_center_rules_title')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RuleTile(
                  icon: Icons.today_outlined,
                  text: t('notif_center_rule_daily'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.warning_amber_rounded,
                  text: t('notif_center_rule_urgent'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.bolt_rounded,
                  text: t('notif_center_rule_test'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.toggle_off_rounded,
                  text: t('notif_center_rule_off'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: t('notif_center_cases_title')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RuleTile(
                  icon: Icons.event_note_outlined,
                  text: t('notif_center_case_daily_when'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.notification_important_outlined,
                  text: t('notif_center_case_urgent_when'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.science_outlined,
                  text: t('notif_center_case_test_when'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.lock_outline_rounded,
                  text: t('notif_center_case_permission_when'),
                ),
                const Divider(height: 1),
                _RuleTile(
                  icon: Icons.error_outline_rounded,
                  text: t('notif_center_case_failed_when'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: t('notif_center_logs_title')),
          const SizedBox(height: 8),
          if (provider.notificationLogs.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: Text(t('notif_center_logs_empty')),
              ),
            )
          else
            ...provider.notificationLogs.map(
              (row) => _LogTile(
                row: row,
                t: t,
                onToggleRead: (id, nextRead) {
                  provider.markNotificationLogRead(id, isRead: nextRead);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(
        text,
        style: TextStyle(color: cs.onSurface),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.row,
    required this.t,
    required this.onToggleRead,
  });

  final Map<String, dynamic> row;
  final String Function(String) t;
  final void Function(String id, bool nextRead) onToggleRead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = (row['title'] as String?)?.trim();
    final message = (row['message'] as String?)?.trim();
    final id = (row['id'] as String?)?.trim() ?? '';
    final isRead = row['isRead'] == true;
    final createdAt = (row['createdAt'] as String?)?.trim() ??
        (row['created_at'] as String?)?.trim() ??
        '';

    return Card(
      child: ListTile(
        leading: Icon(
          isRead
              ? Icons.mark_email_read_rounded
              : Icons.mark_email_unread_rounded,
          color: isRead ? cs.onSurfaceVariant : cs.primary,
        ),
        title: Text(
          title == null || title.isEmpty ? '-' : title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null && message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message),
              ),
            if (createdAt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  createdAt,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        trailing: id.isEmpty
            ? null
            : TextButton(
                onPressed: () => onToggleRead(id, !isRead),
                child: Text(
                  isRead
                      ? t('notif_center_mark_unread')
                      : t('notif_center_mark_read'),
                ),
              ),
      ),
    );
  }
}
