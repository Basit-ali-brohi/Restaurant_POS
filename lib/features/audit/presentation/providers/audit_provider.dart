import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pos/domain/models/pos_models.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../../../inventory/presentation/providers/stock_provider.dart';

/// Forensic event categories.
enum AuditCategory {
  sales('Sales', Icons.point_of_sale, AppColors.accent),
  inventory('Inventory', Icons.inventory_2_outlined, AppColors.info),
  staff('Staff', Icons.badge_outlined, AppColors.success),
  security('Security', Icons.shield_outlined, Color(0xFF8B5CF6)),
  system('System', Icons.settings_outlined, Color(0xFF94A3B8));

  const AuditCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// An immutable record of a single system state mutation.
class AuditEntry {
  final AuditCategory category;
  final String action;
  final String detail;
  final String actor;
  final DateTime at;

  const AuditEntry({
    required this.category,
    required this.action,
    required this.detail,
    required this.actor,
    required this.at,
  });
}

/// Active category filter for the forensic log.
final auditFilterProvider = StateProvider<AuditCategory?>((ref) => null);

/// Writable forensic sink. Actions that aren't already derivable from live
/// state (logins, role switches, blocked-access attempts, approvals) append
/// here so they appear in the unified trail.
class AuditTrailNotifier extends StateNotifier<List<AuditEntry>> {
  AuditTrailNotifier() : super(const []) {
    _load();
  }

  final _db = DbService.instance;

  static String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows =
        await _db.rows('SELECT * FROM audit_log ORDER BY at DESC LIMIT 300');
    state = [
      for (final r in rows)
        AuditEntry(
          category: AuditCategory.values.firstWhere(
              (c) => c.name == r['category'],
              orElse: () => AuditCategory.system),
          action: r['action'] ?? '',
          detail: r['detail'] ?? '',
          actor: r['actor'] ?? '',
          at: DateTime.tryParse(r['at'] ?? '') ?? DateTime.now(),
        ),
    ];
  }

  void log({
    required AuditCategory category,
    required String action,
    required String detail,
    required String actor,
  }) {
    final entry = AuditEntry(
      category: category,
      action: action,
      detail: detail,
      actor: actor,
      at: DateTime.now(),
    );
    state = [entry, ...state];
    _db.exec(
      'INSERT INTO audit_log (category,action,detail,actor,at) '
      'VALUES (:c,:a,:d,:ac,:at)',
      {
        'c': category.name,
        'a': action,
        'd': detail,
        'ac': actor,
        'at': _fmt(entry.at),
      },
    );
  }
}

final auditTrailProvider =
    StateNotifierProvider<AuditTrailNotifier, List<AuditEntry>>(
        (ref) => AuditTrailNotifier());

/// Seeded non-derivable events (security / staff / system).
List<AuditEntry> _seededEvents() {
  final now = DateTime.now();
  return [
    AuditEntry(
        category: AuditCategory.security,
        action: 'Role permissions updated',
        detail: 'Manager · enabled "Void Orders"',
        actor: 'Admin',
        at: now.subtract(const Duration(minutes: 6))),
    AuditEntry(
        category: AuditCategory.system,
        action: 'Menu changes published',
        detail: '3 items modified in Mains',
        actor: 'Admin',
        at: now.subtract(const Duration(minutes: 14))),
    AuditEntry(
        category: AuditCategory.staff,
        action: 'Clock-in',
        detail: 'Marcus Vance · Head Chef',
        actor: 'Marcus Vance',
        at: now.subtract(const Duration(minutes: 33))),
    AuditEntry(
        category: AuditCategory.system,
        action: 'Tax profile synced',
        detail: 'GST 17% reconciled with FBR channel',
        actor: 'System',
        at: now.subtract(const Duration(minutes: 51))),
    AuditEntry(
        category: AuditCategory.security,
        action: 'User login',
        detail: 'Admin · Terminal #04',
        actor: 'Admin',
        at: now.subtract(const Duration(hours: 1, minutes: 12))),
  ];
}

/// Unified, chronological (newest-first) forensic feed derived from live state.
final auditLogProvider = Provider<List<AuditEntry>>((ref) {
  final orders = ref.watch(orderRepositoryProvider);
  final movements = ref.watch(stockMovementsProvider);

  final entries = <AuditEntry>[
    ..._seededEvents(),
    ...ref.watch(auditTrailProvider),
  ];

  for (final OrderRecord o in orders) {
    final route = o.orderType == OrderType.dineIn && o.tableName != null
        ? 'Table ${o.tableName}'
        : o.orderType.label;
    entries.add(AuditEntry(
      category: AuditCategory.sales,
      action: o.payment != null ? 'Payment settled' : 'Bill generated',
      detail:
          '#${o.billNumber} · $route · PKR ${o.breakdown.grandTotal.toStringAsFixed(2)}'
          '${o.payment != null ? ' · ${o.payment!.methodLabel}' : ''}',
      actor: 'Cashier',
      at: o.createdAt,
    ));
  }

  for (final m in movements) {
    entries.add(AuditEntry(
      category: AuditCategory.inventory,
      action: m.type.label,
      detail: '${m.itemName} ${m.deltaLabel}'
          '${m.reason != null ? ' · ${m.reason}' : ''}'
          '${m.fromBranch != null ? ' · ${m.fromBranch}→${m.toBranch}' : ''}',
      actor: m.by,
      at: m.at,
    ));
  }

  entries.sort((a, b) => b.at.compareTo(a.at));
  return entries;
});

/// Per-category counts for the report summary cards.
final auditCountsProvider = Provider<Map<AuditCategory, int>>((ref) {
  final entries = ref.watch(auditLogProvider);
  final counts = {for (final c in AuditCategory.values) c: 0};
  for (final e in entries) {
    counts[e.category] = (counts[e.category] ?? 0) + 1;
  }
  return counts;
});
