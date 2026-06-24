import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/stock_models.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_movement_sheet.dart';
import '../widgets/stock_transfer_sheet.dart';

/// SCREENS 27–28 — Inventory Dashboard & Stock List. A dense valuation grid
/// over raw ingredients & packaging with low/expiring flags, KPI headers and an
/// audited movement log. Row actions open the Add/Adjust/Wastage and Transfer
/// overlays (Screens 29–32).
class StockControlScreen extends ConsumerWidget {
  const StockControlScreen({super.key});

  static String _money(double v) {
    final whole = v.toStringAsFixed(2);
    final parts = whole.split('.');
    final buf = StringBuffer();
    for (int i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
      buf.write(parts[0][i]);
    }
    return 'PKR $buf.${parts[1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final kpis = ref.watch(stockKpisProvider);
    final filter = ref.watch(stockCategoryFilterProvider);
    final allItems = ref.watch(stockItemsProvider);
    final items = filter == null
        ? allItems
        : allItems.where((i) => i.category == filter).toList();

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inventory Matrix',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Real-time stock monitoring and culinary asset valuation.',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _toast(context, 'Inventory log exported'),
                  icon: Icon(Icons.download, size: 16, color: t.textSecondary),
                  label: Text('Export Log',
                      style: TextStyle(
                          color: t.textPrimary, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddItem(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // KPI cards.
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 3 * 16) / 4;
              final cardW = w < 200 ? c.maxWidth : w;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(t, 'TOTAL STOCK VALUE', _money(kpis.totalValue),
                      Icons.account_balance_wallet_outlined, AppColors.accent,
                      width: cardW),
                  _kpi(t, 'LOW STOCK', '${kpis.lowCount} Items',
                      Icons.warning_amber_rounded, AppColors.warning,
                      width: cardW, highlight: kpis.lowCount > 0),
                  _kpi(t, 'OUT OF STOCK', '${kpis.outCount} Items',
                      Icons.remove_shopping_cart_outlined, AppColors.error,
                      width: cardW),
                  _kpi(t, 'EXPIRING SOON', '${kpis.expiringCount} Items',
                      Icons.schedule, AppColors.info,
                      width: cardW),
                ],
              );
            }),
            const SizedBox(height: 20),
            // Category filter.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _filterChip(ref, t, null, 'All Items', filter == null),
                for (final cat in StockCategory.values)
                  _filterChip(ref, t, cat, cat.label, filter == cat),
              ],
            ),
            const SizedBox(height: 16),
            // Data grid.
            _grid(context, ref, t, items),
            const SizedBox(height: 20),
            _auditLog(t, ref),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint,
      {required double width, bool highlight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlight ? tint.withValues(alpha: 0.6) : t.border,
            width: highlight ? 1.4 : 1),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
              const Spacer(),
              Icon(icon, size: 18, color: tint),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, AppTones t, StockCategory? cat,
      String label, bool selected) {
    return GestureDetector(
      onTap: () => ref.read(stockCategoryFilterProvider.notifier).state = cat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accent : t.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : t.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }

  Widget _grid(BuildContext context, WidgetRef ref, AppTones t,
      List<StockItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          // Header row.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _h(t, 'ITEM DETAILS')),
                Expanded(flex: 2, child: _h(t, 'SKU')),
                Expanded(flex: 2, child: _h(t, 'STOCK LEVEL')),
                Expanded(flex: 2, child: _h(t, 'UNIT COST')),
                Expanded(flex: 2, child: _h(t, 'VALUATION')),
                SizedBox(width: 110, child: _h(t, 'STATUS')),
                const SizedBox(width: 150, child: SizedBox()),
              ],
            ),
          ),
          for (int i = 0; i < items.length; i++)
            _row(context, ref, t, items[i], last: i == items.length - 1),
        ],
      ),
    );
  }

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));

  Widget _row(BuildContext context, WidgetRef ref, AppTones t, StockItem item,
      {required bool last}) {
    final statusColor = item.isOut
        ? AppColors.error
        : item.isLow
            ? AppColors.warning
            : AppColors.success;
    final expiring = item.isExpiringSoon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    if (expiring) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Expiring',
                            style: TextStyle(
                                color: AppColors.info,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(item.category.label,
                    style: TextStyle(color: t.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(item.sku,
                style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
          ),
          Expanded(
            flex: 2,
            child: Text(item.quantityLabel,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ),
          Expanded(
            flex: 2,
            child: Text(_money(item.unitCost),
                style: TextStyle(color: t.textSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(_money(item.valuation),
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ),
          ),
          SizedBox(
            width: 184,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _action(t, Icons.add, AppColors.success, 'Add stock',
                    () => StockMovementSheet.show(context, item.id,
                        initial: MovementType.received)),
                _action(t, Icons.tune, AppColors.info, 'Adjust',
                    () => StockMovementSheet.show(context, item.id,
                        initial: MovementType.adjustment)),
                _action(t, Icons.delete_sweep, AppColors.error, 'Wastage',
                    () => StockMovementSheet.show(context, item.id,
                        initial: MovementType.wastage)),
                _action(t, Icons.swap_horiz, AppColors.warning, 'Transfer',
                    () => StockTransferSheet.show(context, item.id)),
                _action(t, Icons.delete_outline, const Color(0xFF64748B),
                    'Delete item', () => _confirmDelete(context, ref, item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
      AppTones t, IconData icon, Color color, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StockItem item) {
    final t = AppTones(ref.read(themeProvider));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Delete item?',
            style: TextStyle(
                color: t.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Remove "${item.name}" from inventory permanently?',
            style: TextStyle(color: t.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: t.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(stockControllerProvider.notifier).removeItem(item.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItem(BuildContext context, WidgetRef ref) async {
    final t = AppTones(ref.read(themeProvider));
    final name = TextEditingController();
    final sku = TextEditingController();
    final unit = TextEditingController(text: 'kg');
    final qty = TextEditingController();
    final cost = TextEditingController();
    final low = TextEditingController(text: '5');
    final par = TextEditingController(text: '20');
    StockCategory category = StockCategory.rawIngredients;
    String? error;

    InputDecoration dec(String hint) => InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: t.textMuted),
          filled: true,
          fillColor: t.surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        );

    Widget field(String label, TextEditingController c, String hint,
            {bool number = false}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: t.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(
            controller: c,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: TextStyle(color: t.textPrimary, fontSize: 14),
            decoration: dec(hint),
          ),
        ]);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: t.border))),
                  child: Row(children: [
                    Text('Add Inventory Item',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: t.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ]),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        field('Item name', name, 'e.g. Basmati Rice'),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: field('SKU', sku, 'DG-RICE-002')),
                          const SizedBox(width: 12),
                          Expanded(child: field('Unit', unit, 'kg / g / L')),
                        ]),
                        const SizedBox(height: 12),
                        Text('Category',
                            style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: t.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<StockCategory>(
                              isExpanded: true,
                              value: category,
                              dropdownColor: t.surface,
                              style: TextStyle(
                                  color: t.textPrimary, fontSize: 14),
                              items: StockCategory.values
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c.label)))
                                  .toList(),
                              onChanged: (v) =>
                                  setLocal(() => category = v ?? category),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: field('Quantity', qty, '0', number: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: field('Unit cost (PKR)', cost, '0',
                                  number: true)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: field('Low threshold', low, '5',
                                  number: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  field('Par level', par, '20', number: true)),
                        ]),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.border))),
                  child: Row(children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:
                          Text('Cancel', style: TextStyle(color: t.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final n = name.text.trim();
                        final q = double.tryParse(qty.text.trim());
                        final c = double.tryParse(cost.text.trim());
                        if (n.isEmpty) {
                          setLocal(() => error = 'Item name is required');
                          return;
                        }
                        if (q == null || c == null) {
                          setLocal(() =>
                              error = 'Enter valid quantity and unit cost');
                          return;
                        }
                        ref.read(stockControllerProvider.notifier).createItem(
                              name: n,
                              sku: sku.text.trim(),
                              category: category,
                              unit: unit.text.trim().isEmpty
                                  ? 'unit'
                                  : unit.text.trim(),
                              quantity: q,
                              unitCost: c,
                              lowThreshold:
                                  double.tryParse(low.text.trim()) ?? 0,
                              parLevel: double.tryParse(par.text.trim()) ?? 0,
                            );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add Item',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _auditLog(AppTones t, WidgetRef ref) {
    final movements = ref.watch(stockMovementsProvider);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text('Movement Audit Log',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('(${movements.length})',
                    style: TextStyle(color: t.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          if (movements.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                    'No movements yet — add, adjust, waste or transfer stock above',
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
              ),
            )
          else
            for (final m in movements.take(12)) _logRow(t, m),
        ],
      ),
    );
  }

  Widget _logRow(AppTones t, StockMovement m) {
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(m.at.hour)}:${two(m.at.minute)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: m.type.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(m.type.icon, size: 16, color: m.type.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.type.label} · ${m.itemName}',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text([
                  if (m.reason != null) m.reason!,
                  if (m.fromBranch != null) '${m.fromBranch} → ${m.toBranch}',
                  if (m.note != null) m.note!,
                  'by ${m.by} · $time',
                ].join('  ·  '),
                    style: TextStyle(color: t.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Text(m.deltaLabel,
              style: TextStyle(
                  color: m.delta >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5)),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1000),
      backgroundColor: AppColors.success,
    ));
  }
}
