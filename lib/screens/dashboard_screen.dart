import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../screens/ai_chat_screen.dart';
import '../widgets/add_food_modal.dart';
import '../constants/categories.dart';
import '../utils/date_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;

    final expired = provider.expiredItems;
    final expiringSoon = provider.expiringSoonItems;
    final recent = provider.inventory.take(5).toList();
    final goodCount = provider.inventory
        .where((i) => !i.isExpired && !i.isExpiringSoon)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco_rounded,
                color: Theme.of(context).colorScheme.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              'Harvest & Hearth',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(provider.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: t('profile_dark_mode'),
            onPressed: () => context.read<AppProvider>().toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _WelcomeBanner(provider: provider),
          const SizedBox(height: 20),
          _StatsRow(
            total: provider.inventory.length,
            expiredCount: expired.length,
            expiringCount: expiringSoon.length,
            goodCount: goodCount,
            t: t,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: t('dashboard_quick_actions')),
          const SizedBox(height: 10),
          _QuickActionGrid(provider: provider),
          const SizedBox(height: 20),
          _AiChatPreviewCard(provider: provider),
          const SizedBox(height: 20),
          if (expired.isNotEmpty || expiringSoon.isNotEmpty) ...[
            _SectionHeader(title: t('dashboard_alerts')),
            const SizedBox(height: 10),
            _AlertsCard(
              expired: expired,
              expiringSoon: expiringSoon,
              t: t,
              language: provider.language,
            ),
            const SizedBox(height: 20),
          ],
          _SectionHeader(title: t('dashboard_recent')),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            _EmptyCard(message: t('dashboard_no_items'))
          else
            _RecentItemsList(
              items: recent,
              t: t,
              language: provider.language,
            ),
          const SizedBox(height: 20),
          _TipCard(t: t),
        ],
      ),
    );
  }
}

// ── Welcome Banner ──────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final AppProvider provider;
  const _WelcomeBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final name = provider.user?.name ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? (provider.language == 'VIE' ? 'Chào buổi sáng' : 'Good morning')
        : hour < 17
            ? (provider.language == 'VIE'
                ? 'Chào buổi chiều'
                : 'Good afternoon')
            : (provider.language == 'VIE' ? 'Chào buổi tối' : 'Good evening');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withAlpha(204), cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(51),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.amberAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t('dashboard_subtitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int expiredCount;
  final int expiringCount;
  final int goodCount;
  final String Function(String) t;

  const _StatsRow({
    required this.total,
    required this.expiredCount,
    required this.expiringCount,
    required this.goodCount,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_rounded,
            value: '$total',
            label: t('dashboard_stats_total'),
            color: cs.primary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: '$goodCount',
            label: t('dashboard_stats_good'),
            color: Colors.green,
            cs: cs,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: expiredCount > 0
                ? Icons.dangerous_rounded
                : Icons.warning_amber_rounded,
            value: '${expiredCount + expiringCount}',
            label: t('dashboard_stats_attention'),
            color: expiredCount > 0 ? Colors.red : Colors.orange,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Quick Action Grid ───────────────────────────────────────────────────────

class _QuickActionGrid extends StatelessWidget {
  final AppProvider provider;
  const _QuickActionGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.add_circle_outline_rounded,
          label: t('dashboard_quick_add'),
          color: cs.primary,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const AddFoodModal(),
            );
          },
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.qr_code_scanner_rounded,
          label: t('food_barcode'),
          color: Colors.teal,
          onTap: () {
            Navigator.pushNamed(context, '/barcode-scanner');
          },
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.smart_toy_rounded,
          label: t('dashboard_chat_hint'),
          color: cs.secondary,
          isHighlight: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            );
          },
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.restaurant_menu_rounded,
          label: t('dashboard_ai_suggestion'),
          color: Colors.deepPurple,
          onTap: () {
            // Switch to recipes tab is handled by MainShell
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isHighlight;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isHighlight ? color.withAlpha(26) : color.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighlight ? color.withAlpha(77) : color.withAlpha(26),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI Chat Preview Card ────────────────────────────────────────────────────

class _AiChatPreviewCard extends StatelessWidget {
  final AppProvider provider;
  const _AiChatPreviewCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.secondary.withAlpha(51)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.secondary, cs.secondary.withAlpha(153)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('chat_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('chat_subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alerts Card ─────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  final List<FoodItem> expired;
  final List<FoodItem> expiringSoon;
  final String Function(String) t;
  final String language;

  const _AlertsCard({
    required this.expired,
    required this.expiringSoon,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...expired.map((item) => _AlertRow(
                item: item,
                isExpired: true,
                t: t,
                language: language,
              )),
          if (expired.isNotEmpty && expiringSoon.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          ...expiringSoon.take(3).map((item) => _AlertRow(
                item: item,
                isExpired: false,
                t: t,
                language: language,
              )),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final FoodItem item;
  final bool isExpired;
  final String Function(String) t;
  final String language;

  const _AlertRow({
    required this.item,
    required this.isExpired,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired ? Colors.red : Colors.orange;
    final info = AppCategories.forCategory(item.category);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(info.icon, color: color, size: 20),
      ),
      title:
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        DateHelper.relativeLabel(item.daysUntilExpiry, language),
        style: TextStyle(color: color, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isExpired
              ? t('inventory_expired_badge')
              : t('inventory_expiring_badge'),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Recent Items List ───────────────────────────────────────────────────────

class _RecentItemsList extends StatelessWidget {
  final List<FoodItem> items;
  final String Function(String) t;
  final String language;

  const _RecentItemsList({
    required this.items,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: items.map((item) {
        final info = AppCategories.forCategory(item.category);
        final daysLeft = item.daysUntilExpiry;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: info.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(info.icon, color: info.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${item.quantity} ${item.unit}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (daysLeft != null)
                  _ExpiryBadge(
                    daysLeft: daysLeft,
                    isExpired: item.isExpired,
                    isExpiringSoon: item.isExpiringSoon,
                    language: language,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int daysLeft;
  final bool isExpired;
  final bool isExpiringSoon;
  final String language;

  const _ExpiryBadge({
    required this.daysLeft,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired
        ? Colors.red
        : (isExpiringSoon ? Colors.orange : Colors.green);
    final icon = isExpired
        ? Icons.dangerous_rounded
        : (isExpiringSoon
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            DateHelper.relativeLabel(daysLeft, language),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Tip Card ────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String Function(String) t;
  const _TipCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.onSecondaryContainer.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.lightbulb_rounded,
                  color: cs.onSecondaryContainer, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('dashboard_tip'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer)),
                  const SizedBox(height: 4),
                  Text(t('dashboard_tip_text'),
                      style: TextStyle(
                          color: cs.onSecondaryContainer, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ── Empty Card ──────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 40, color: cs.onSurfaceVariant.withAlpha(77)),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
