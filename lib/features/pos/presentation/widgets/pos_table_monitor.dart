import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../table_management/domain/models/table_model.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../../../table_management/presentation/widgets/table_actions_sheet.dart';
import '../providers/pos_providers.dart';

/// Spec colour profile for live table states.
const Color _kReserved = AppColors.warning; // orange
const Color _kCleaning = Color(0xFF8B5CF6); // purple

/// Live floor map shown in the POS left pane while Dine-In is active and no
/// table is yet bound. Tables are colour-coded by state with elapsed timers;
/// tapping an Available table binds the active bill to that table index.
class PosTableMonitor extends ConsumerWidget {
  const PosTableMonitor({super.key});

  static ({Color color, String label, IconData icon}) _statusMeta(
      TableModel table, DateTime now) {
    switch (table.status) {
      case TableStatus.available:
        return (color: AppColors.success, label: 'Available', icon: Icons.check_circle_outline);
      case TableStatus.occupied:
        return (
          color: AppColors.error,
          label: _elapsed(table.occupiedSince, now),
          icon: Icons.timer_outlined
        );
      case TableStatus.reserved:
        return (color: _kReserved, label: 'Reserved', icon: Icons.event_seat_outlined);
      case TableStatus.cleaning:
        return (color: _kCleaning, label: 'Cleaning', icon: Icons.cleaning_services_outlined);
      case TableStatus.billing:
        return (color: AppColors.warning, label: 'Billing', icon: Icons.receipt_long_outlined);
      case TableStatus.outOfService:
        return (color: const Color(0xFF64748B), label: 'Out of Service', icon: Icons.block_outlined);
    }
  }

  static String _elapsed(DateTime? since, DateTime now) {
    if (since == null) return 'Occupied';
    final d = now.difference(since);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final tables = ref.watch(tableProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    final sections = <String, List<TableModel>>{};
    for (final table in tables) {
      sections.putIfAbsent(table.section, () => []).add(table);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Icon(Icons.table_restaurant, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Text('Select a Table',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              _legend(t),
            ],
          ),
        ),
        Divider(height: 1, color: t.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              for (final entry in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: Text(entry.key.toUpperCase(),
                      style: TextStyle(
                          color: t.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final table in entry.value)
                      _TableTile(
                        tones: t,
                        table: table,
                        meta: _statusMeta(table, now),
                        onTap: () {
                          if (table.status == TableStatus.available) {
                            ref
                                .read(selectedTableNameProvider.notifier)
                                .state = table.name;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bill bound to ${table.name}'),
                                duration: const Duration(milliseconds: 900),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            TableActionsSheet.show(context, table.id);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(AppTones t) {
    Widget chip(Color c, String label) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ],
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(AppColors.success, 'Available'),
        chip(AppColors.error, 'Occupied'),
        chip(_kReserved, 'Reserved'),
        chip(_kCleaning, 'Cleaning'),
      ],
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.tones,
    required this.table,
    required this.meta,
    required this.onTap,
  });

  final AppTones tones;
  final TableModel table;
  final ({Color color, String label, IconData icon}) meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Opacity(
          opacity: available ? 1.0 : 0.72,
          child: Container(
            width: 116,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: meta.color.withValues(alpha: 0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(table.name,
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Icon(meta.icon, size: 16, color: meta.color),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_seat, size: 13, color: tones.textMuted),
                    const SizedBox(width: 4),
                    Text('${table.seats}',
                        style: TextStyle(color: tones.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(meta.label,
                      style: TextStyle(
                          color: meta.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
