import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/notifications_provider.dart';

/// SCREEN 7 — Notification Center (full page). System alerts, staff
/// communications and operational updates, filterable by category, with
/// per-card actions — matching the CloudPOS Pro reference.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final filter = ref.watch(notificationFilterProvider);
    final alertsBadge = ref.watch(unreadAlertsCountProvider);
    final base = ref.watch(filteredNotificationsProvider);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? base
        : base
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.message.toLowerCase().contains(q))
            .toList();

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notification Center',
                          style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('Manage system alerts, staff communications, and operational updates.',
                          style: TextStyle(color: t.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 240,
                  height: 44,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon:
                          Icon(Icons.filter_list, size: 18, color: t.textMuted),
                      hintText: 'Filter current view...',
                      hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
                      filled: true,
                      fillColor: t.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.accent, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                    icon: const Icon(Icons.done_all, size: 17),
                    label: const Text('MARK ALL READ',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.4)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.14),
                      foregroundColor: AppColors.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Category tabs.
            Wrap(spacing: 10, runSpacing: 10, children: [
              _tab(t, null, 'All', filter == null, 0),
              _tab(t, NotificationCategory.alerts, 'Alerts',
                  filter == NotificationCategory.alerts, alertsBadge),
              _tab(t, NotificationCategory.staff, 'Staff Messages',
                  filter == NotificationCategory.staff, 0),
              _tab(t, NotificationCategory.orders, 'Orders',
                  filter == NotificationCategory.orders, 0),
              _tab(t, NotificationCategory.finance, 'Finance',
                  filter == NotificationCategory.finance, 0),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: t.border),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: Text('Nothing here',
                        style: TextStyle(color: t.textMuted, fontSize: 14))),
              )
            else
              for (final n in items) _card(t, n),
          ],
        ),
      ),
    );
  }

  Widget _tab(AppTones t, NotificationCategory? cat, String label, bool selected,
      int badge) {
    return GestureDetector(
      onTap: () => ref.read(notificationFilterProvider.notifier).state = cat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (cat == null ? Colors.black : AppColors.accent)
              : t.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.transparent : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : t.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            if (badge > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(AppTones t, NotificationItem n) {
    final color = n.severity.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left severity accent.
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          shape: BoxShape.circle),
                      child: Icon(n.severity.icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(n.title.toUpperCase(),
                                    style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.3)),
                              ),
                              const SizedBox(width: 10),
                              Text(n.timeLabel,
                                  style: TextStyle(
                                      color: t.textMuted, fontSize: 11.5)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(n.message,
                              style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: 13,
                                  height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (n.action != null) _actionButton(t, n, color),
                        const SizedBox(height: 8),
                        if (!n.read)
                          GestureDetector(
                            onTap: () => ref
                                .read(notificationsProvider.notifier)
                                .markRead(n.id),
                            child: Text('MARK READ',
                                style: TextStyle(
                                    color: t.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    letterSpacing: 0.5)),
                          )
                        else
                          Row(children: [
                            Icon(Icons.check, size: 13, color: t.textMuted),
                            const SizedBox(width: 4),
                            Text('Read',
                                style: TextStyle(
                                    color: t.textMuted, fontSize: 10.5)),
                          ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(AppTones t, NotificationItem n, Color color) {
    // Critical/warning use a solid coloured button; info/success use a tint.
    final solid = n.severity == NotificationSeverity.critical ||
        n.severity == NotificationSeverity.warning;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${n.action} — ${n.title}'),
          duration: const Duration(milliseconds: 1000),
        )),
        style: ElevatedButton.styleFrom(
          backgroundColor: solid ? color : color.withValues(alpha: 0.14),
          foregroundColor: solid ? Colors.white : color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(n.action!.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: 0.3)),
      ),
    );
  }
}
