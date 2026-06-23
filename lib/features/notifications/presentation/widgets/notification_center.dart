import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/notifications_provider.dart';

/// SCREEN 7 — Notification Center. A bell that anchors a dismissible overlay
/// panel, filterable by category (Orders, Inventory, Attendance, Finance).
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  void _toggle() => _open ? _close() : _openPanel();

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _openPanel() {
    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Dismiss barrier.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),
              child: Align(
                alignment: Alignment.topRight,
                child: _NotificationPanel(onClose: _close),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final unread = ref.watch(unreadNotificationCountProvider);

    return CompositedTransformTarget(
      link: _link,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _open ? AppColors.accent.withValues(alpha: 0.14) : t.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _open ? AppColors.accent : t.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 20,
                    color: _open ? AppColors.accent : t.textSecondary),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.surface, width: 1.5),
                      ),
                      child: Text('$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final filter = ref.watch(notificationFilterProvider);
    final items = ref.watch(filteredNotificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Text('Notifications',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$unread new',
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32)),
                    child: const Text('Mark all read',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // Category filter.
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _filterChip(ref, t, null, 'All', filter == null),
                  for (final c in NotificationCategory.values)
                    _filterChip(ref, t, c, c.label, filter == c),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: t.border),
            // List.
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(36),
                      child: Center(
                        child: Text('Nothing here',
                            style:
                                TextStyle(color: t.textMuted, fontSize: 13)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: t.border),
                      itemBuilder: (context, i) =>
                          _row(ref, t, items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, AppTones t, NotificationCategory? cat,
      String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () =>
            ref.read(notificationFilterProvider.notifier).state = cat,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : t.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: selected ? AppColors.accent : t.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : t.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5)),
        ),
      ),
    );
  }

  Widget _row(WidgetRef ref, AppTones t, NotificationItem n) {
    return InkWell(
      onTap: () => ref.read(notificationsProvider.notifier).markRead(n.id),
      child: Container(
        color: n.read ? Colors.transparent : n.category.color.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: n.category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(n.category.icon, size: 17, color: n.category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5)),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.message,
                      style: TextStyle(color: t.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(n.timeLabel,
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
