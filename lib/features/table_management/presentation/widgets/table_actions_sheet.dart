import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/table_model.dart';
import '../providers/table_provider.dart';

/// SCREEN 16 — Table Detail actions. Prompts Merge / Transfer / Close for a
/// tapped table and applies the change to the shared table state.
class TableActionsSheet extends ConsumerStatefulWidget {
  const TableActionsSheet({super.key, required this.tableId});
  final String tableId;

  static Future<void> show(BuildContext context, String tableId) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => TableActionsSheet(tableId: tableId),
    );
  }

  @override
  ConsumerState<TableActionsSheet> createState() => _TableActionsSheetState();
}

enum _View { menu, transfer, merge }

class _TableActionsSheetState extends ConsumerState<TableActionsSheet> {
  _View _view = _View.menu;

  String _statusLabel(TableModel t) {
    switch (t.status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.cleaning:
        return 'Cleaning';
      case TableStatus.billing:
        return 'Billing';
      case TableStatus.outOfService:
        return 'Out of Service';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1100),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final table = ref.watch(tableProvider.select(
        (list) => list.firstWhere((e) => e.id == widget.tableId)));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(t, table),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_view),
                    child: _view == _View.menu
                        ? _menu(t, table)
                        : _targetPicker(t, table),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppTones t, TableModel table) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(table.name,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Table ${table.name}',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(
                    '${_statusLabel(table)} · ${table.seats} seats · ${table.section}',
                    style: TextStyle(color: t.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: t.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _menu(AppTones t, TableModel table) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionTile(t,
              icon: Icons.merge_type,
              color: AppColors.info,
              title: 'Merge Table',
              subtitle: 'Combine this party into another occupied table',
              onTap: () => setState(() => _view = _View.merge)),
          const SizedBox(height: 12),
          _actionTile(t,
              icon: Icons.swap_horiz,
              color: AppColors.warning,
              title: 'Transfer Table',
              subtitle: 'Move this seating to an available table',
              onTap: () => setState(() => _view = _View.transfer)),
          const SizedBox(height: 12),
          _actionTile(t,
              icon: Icons.cleaning_services,
              color: AppColors.error,
              title: 'Close Table',
              subtitle: 'Free the table and send it to cleaning',
              onTap: () {
                ref.read(tableProvider.notifier).closeTable(table.id);
                Navigator.of(context).pop();
                _toast('Table ${table.name} closed → cleaning');
              }),
          if (table.status == TableStatus.cleaning) ...[
            const SizedBox(height: 12),
            _actionTile(t,
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                title: 'Mark Available',
                subtitle: 'Return this table to service',
                onTap: () {
                  ref.read(tableProvider.notifier).markAvailable(table.id);
                  Navigator.of(context).pop();
                  _toast('Table ${table.name} is now available');
                }),
          ],
          const SizedBox(height: 12),
          if (table.status == TableStatus.outOfService)
            _actionTile(t,
                icon: Icons.restart_alt,
                color: AppColors.success,
                title: 'Return to Service',
                subtitle: 'Bring this table back to the available pool',
                onTap: () {
                  ref.read(tableProvider.notifier).returnToService(table.id);
                  Navigator.of(context).pop();
                  _toast('Table ${table.name} returned to service');
                })
          else
            _actionTile(t,
                icon: Icons.block_outlined,
                color: const Color(0xFF64748B),
                title: 'Mark Out of Service',
                subtitle: 'Block this table (maintenance / damage)',
                onTap: () {
                  ref.read(tableProvider.notifier).setOutOfService(table.id);
                  Navigator.of(context).pop();
                  _toast('Table ${table.name} marked out of service');
                }),
        ],
      ),
    );
  }

  Widget _actionTile(AppTones t,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: t.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetPicker(AppTones t, TableModel table) {
    final isMerge = _view == _View.merge;
    final all = ref.watch(tableProvider);
    final candidates = all.where((e) {
      if (e.id == table.id) return false;
      return isMerge
          ? e.status == TableStatus.occupied
          : e.status == TableStatus.available;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _view = _View.menu),
                child: Icon(Icons.arrow_back, size: 20, color: t.textSecondary),
              ),
              const SizedBox(width: 10),
              Text(
                  isMerge
                      ? 'Merge into which table?'
                      : 'Transfer to which table?',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
        Flexible(
          child: candidates.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                        isMerge
                            ? 'No occupied tables to merge into'
                            : 'No available tables to transfer to',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in candidates)
                        GestureDetector(
                          onTap: () {
                            final notifier =
                                ref.read(tableProvider.notifier);
                            if (isMerge) {
                              notifier.mergeTables(table.id, c.id);
                              _toast('${table.name} merged into ${c.name}');
                            } else {
                              notifier.transferTable(table.id, c.id);
                              _toast('${table.name} transferred to ${c.name}');
                            }
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 92,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: t.border),
                            ),
                            child: Column(
                              children: [
                                Text(c.name,
                                    style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 2),
                                Text('${c.seats} seats',
                                    style: TextStyle(
                                        color: t.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
