import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../../domain/models/table_model.dart';
import '../providers/table_provider.dart';
import '../widgets/table_actions_sheet.dart';

/// SCREENS 15–16 — Floor & Tables (clean rebuild). A color-coded live table
/// grid on the app design system: KPI header, floor tabs, search, and tap →
/// Merge / Transfer / Close actions. No glassmorphism, no rising animations.
class FloorMonitorScreen extends ConsumerStatefulWidget {
  const FloorMonitorScreen({super.key});

  @override
  ConsumerState<FloorMonitorScreen> createState() => _FloorMonitorScreenState();
}

class _FloorMonitorScreenState extends ConsumerState<FloorMonitorScreen> {
  String _section = 'Ground Floor';
  String _query = '';

  static const Color _reserved = Color(0xFFFB923C); // orange
  static const Color _cleaning = Color(0xFF8B5CF6); // purple

  ({Color color, String label, IconData icon}) _meta(
      TableModel tb, DateTime now) {
    switch (tb.status) {
      case TableStatus.available:
        return (color: AppColors.success, label: 'Available', icon: Icons.check_circle_outline);
      case TableStatus.occupied:
        return (color: AppColors.error, label: _elapsed(tb.occupiedSince, now), icon: Icons.timer_outlined);
      case TableStatus.reserved:
        return (color: _reserved, label: 'Reserved', icon: Icons.event_seat_outlined);
      case TableStatus.cleaning:
        return (color: _cleaning, label: 'Cleaning', icon: Icons.cleaning_services_outlined);
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
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final tables = ref.watch(tableProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    final sections = <String>{for (final tb in tables) tb.section}.toList();
    final q = _query.trim().toLowerCase();
    final inSection = tables
        .where((tb) =>
            tb.section == _section &&
            (q.isEmpty || tb.name.toLowerCase().contains(q)))
        .toList();

    int countWhere(bool Function(TableModel) f) => tables.where(f).length;
    final occupied = countWhere((tb) =>
        tb.status == TableStatus.occupied || tb.status == TableStatus.billing);
    final available = countWhere((tb) => tb.status == TableStatus.available);
    final reserved = countWhere((tb) => tb.status == TableStatus.reserved);
    final cleaning = countWhere((tb) => tb.status == TableStatus.cleaning);
    final oos = countWhere((tb) => tb.status == TableStatus.outOfService);

    return Container(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI header + search.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(spacing: 12, runSpacing: 12, children: [
                    _kpi(t, 'Total', '${tables.length}', AppColors.accent),
                    _kpi(t, 'Occupied', '$occupied', AppColors.error),
                    _kpi(t, 'Available', '$available', AppColors.success),
                    _kpi(t, 'Reserved', '$reserved', _reserved),
                    _kpi(t, 'Cleaning', '$cleaning', _cleaning),
                    if (oos > 0)
                      _kpi(t, 'Out of Service', '$oos', const Color(0xFF64748B)),
                  ]),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  height: 44,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: t.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon:
                          Icon(Icons.search, size: 18, color: t.textMuted),
                      hintText: 'Search table…',
                      hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
                      filled: true,
                      fillColor: t.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floor tabs.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(children: [
              for (final s in sections)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _section = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: _section == s ? AppColors.accent : t.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _section == s ? AppColors.accent : t.border),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              color: _section == s
                                  ? Colors.white
                                  : t.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ),
              const Spacer(),
              _legend(t),
            ]),
          ),
          Divider(height: 1, color: t.border),
          // Grid.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final tb in inSection)
                    _TableCard(
                      tones: t,
                      table: tb,
                      meta: _meta(tb, now),
                      onTap: () => TableActionsSheet.show(context, tb.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, Color color) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _legend(AppTones t) {
    Widget chip(Color c, String l) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(l, style: TextStyle(color: t.textSecondary, fontSize: 11)),
          ]),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      chip(AppColors.success, 'Available'),
      chip(AppColors.error, 'Occupied'),
      chip(_reserved, 'Reserved'),
      chip(_cleaning, 'Cleaning'),
    ]);
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard(
      {required this.tones,
      required this.table,
      required this.meta,
      required this.onTap});
  final AppTones tones;
  final TableModel table;
  final ({Color color, String label, IconData icon}) meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: meta.color.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.table_restaurant,
                      size: 17, color: meta.color),
                ),
                const Spacer(),
                Text(table.name,
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.event_seat, size: 13, color: tones.textMuted),
                const SizedBox(width: 4),
                Text('${table.seats} seats',
                    style: TextStyle(color: tones.textMuted, fontSize: 11.5)),
                if (table.guestCount != null) ...[
                  const Spacer(),
                  Text('${table.guestCount} guests',
                      style: TextStyle(color: tones.textMuted, fontSize: 11)),
                ],
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  Icon(meta.icon, size: 13, color: meta.color),
                  const SizedBox(width: 5),
                  Text(meta.label,
                      style: TextStyle(
                          color: meta.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
