import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/theme/app_colors.dart';

/// Notification categories used by the filterable Notification Center.
enum NotificationCategory {
  alerts('Alerts', Icons.warning_amber_rounded, AppColors.error),
  staff('Staff Messages', Icons.badge, AppColors.success),
  orders('Orders', Icons.receipt_long, AppColors.info),
  finance('Finance', Icons.payments, AppColors.accent);

  const NotificationCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Visual severity — drives the card's left accent border + icon colour.
enum NotificationSeverity {
  critical(AppColors.error, Icons.error_outline),
  warning(AppColors.warning, Icons.schedule),
  info(AppColors.accent, Icons.info_outline),
  success(AppColors.success, Icons.check_circle_outline);

  const NotificationSeverity(this.color, this.icon);
  final Color color;
  final IconData icon;
}

class NotificationItem {
  final String id;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final String title;
  final String message;
  final String timeLabel;
  final String? action;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.action,
    this.read = false,
  });

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        category: category,
        severity: severity,
        title: title,
        message: message,
        timeLabel: timeLabel,
        action: action,
        read: read ?? this.read,
      );
}

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super(_seed);

  static const List<NotificationItem> _seed = [
    NotificationItem(
        id: 'n1',
        category: NotificationCategory.alerts,
        severity: NotificationSeverity.critical,
        title: 'Critical Stock Alert',
        message:
            'Saffron Threads (Premium) inventory has fallen below the critical threshold of 5g. Immediate restock required for evening service.',
        timeLabel: 'Just now',
        action: 'Order Stock'),
    NotificationItem(
        id: 'n2',
        category: NotificationCategory.orders,
        severity: NotificationSeverity.warning,
        title: 'Delayed Delivery',
        message:
            "Table 12's order #8292 is currently 15 minutes late from the kitchen projected time.",
        timeLabel: '15 mins ago',
        action: 'View Order'),
    NotificationItem(
        id: 'n3',
        category: NotificationCategory.finance,
        severity: NotificationSeverity.info,
        title: 'System Update',
        message:
            'CloudPOS Pro Version 2.4.1 will be deployed tonight at 2:00 AM local time. Expect brief offline capability mode.',
        timeLabel: '2 hours ago',
        action: 'Release Notes'),
    NotificationItem(
        id: 'n4',
        category: NotificationCategory.staff,
        severity: NotificationSeverity.info,
        title: 'Schedule Published',
        message:
            'Front-of-house staff schedule for the upcoming week (Oct 12 - Oct 18) has been successfully published and distributed.',
        timeLabel: 'Yesterday, 4:30 PM',
        action: 'View Roster',
        read: true),
    NotificationItem(
        id: 'n5',
        category: NotificationCategory.orders,
        severity: NotificationSeverity.success,
        title: 'Online Order Received',
        message: 'New Foodpanda order #FP-8841 routed to the kitchen stations.',
        timeLabel: '5 mins ago',
        action: 'View Order'),
    NotificationItem(
        id: 'n6',
        category: NotificationCategory.staff,
        severity: NotificationSeverity.success,
        title: 'Clock-in Recorded',
        message: 'Chef Imran clocked in at the Main Grill station — on time.',
        timeLabel: '38 mins ago',
        read: true),
  ];

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        (ref) => NotificationsNotifier());

/// Active category filter (null = All).
final notificationFilterProvider =
    StateProvider<NotificationCategory?>((ref) => null);

final filteredNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final all = ref.watch(notificationsProvider);
  final filter = ref.watch(notificationFilterProvider);
  if (filter == null) return all;
  return all.where((n) => n.category == filter).toList();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});

/// Count of unread "alert" severity items for the tab badge.
final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .where((n) => !n.read && n.severity == NotificationSeverity.critical)
      .length;
});
