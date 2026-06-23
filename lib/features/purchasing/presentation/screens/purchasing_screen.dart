import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../inventory/domain/models/stock_models.dart';
import '../../../inventory/presentation/providers/stock_provider.dart';
import '../../domain/models/purchase_order.dart';
import '../providers/purchase_order_provider.dart';

/// SRS 4.3 — Purchase Order Hub. Full CRUD + lifecycle: Draft → Pending
/// Approval → Approved → Dispatched → Received (updates the stock ledger).
class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final all = ref.watch(purchaseOrderProvider);
    final filter = ref.watch(poStatusFilterProvider);
    final pos = filter == null
        ? all
        : all.where((p) => p.status == filter).toList();

    int countAt(POStatus s) => all.where((p) => p.status == s).length;
    final inTransit = countAt(POStatus.dispatched);
    final pending = countAt(POStatus.pendingApproval);
    final committed = all
        .where((p) =>
            p.status != POStatus.received && p.status != POStatus.rejected)
        .fold(0.0, (s, p) => s + p.total);

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
                    Text('Purchase Orders',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Requisition lifecycle — draft, approval, receiving.',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _CreatePOSheet.show(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Purchase Order',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Total POs', '${all.length}',
                  Icons.description_outlined, AppColors.accent),
              _kpi(t, 'Pending Approval', '$pending',
                  Icons.pending_actions_outlined, AppColors.warning),
              _kpi(t, 'In Transit', '$inTransit',
                  Icons.local_shipping_outlined, const Color(0xFF8B5CF6)),
              _kpi(t, 'Committed Spend', _money(committed),
                  Icons.account_balance_wallet_outlined, AppColors.info),
            ]),
            const SizedBox(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _chip(ref, t, null, 'All', filter == null),
              for (final s in POStatus.values)
                _chip(ref, t, s, s.label, filter == s),
            ]),
            const SizedBox(height: 16),
            if (pos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text('No purchase orders here',
                      style: TextStyle(color: t.textMuted, fontSize: 14)),
                ),
              )
            else
              for (final po in pos) _poCard(context, t, ref, po),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(WidgetRef ref, AppTones t, POStatus? s, String label,
      bool selected) {
    return GestureDetector(
      onTap: () => ref.read(poStatusFilterProvider.notifier).state = s,
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

  Widget _poCard(
      BuildContext context, AppTones t, WidgetRef ref, PurchaseOrder po) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_long,
                    size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PO #${po.poNumber}  ·  ${po.supplier}',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                    Text('${po.itemCount} item(s)  ·  ${_money(po.total)}',
                        style: TextStyle(color: t.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: po.status.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(po.status.label,
                    style: TextStyle(
                        color: po.status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5)),
              ),
            ]),
          ),
          Divider(height: 1, color: t.border),
          // Lines.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                for (final l in po.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text(l.name,
                            style: TextStyle(
                                color: t.textSecondary, fontSize: 13)),
                      ),
                      Text(l.qtyLabel,
                          style: TextStyle(color: t.textMuted, fontSize: 12.5)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: Text(_money(l.lineTotal),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          // Lifecycle actions.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              ..._actionsFor(context, ref, po, t),
              const Spacer(),
              if (po.status == POStatus.draft ||
                  po.status == POStatus.rejected)
                GestureDetector(
                  onTap: () =>
                      ref.read(purchaseOrderProvider.notifier).delete(po.id),
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 16,
                        color: AppColors.error.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text('Delete',
                        style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5)),
                  ]),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(
      BuildContext context, WidgetRef ref, PurchaseOrder po, AppTones t) {
    final n = ref.read(purchaseOrderProvider.notifier);
    void toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.success));

    switch (po.status) {
      case POStatus.draft:
        return [
          _btn(t, 'Submit for Approval', AppColors.accent, true, () {
            n.submit(po.id);
            toast('PO #${po.poNumber} submitted');
          }),
        ];
      case POStatus.pendingApproval:
        return [
          _btn(t, 'Approve', AppColors.success, true, () {
            n.approve(po.id);
            toast('PO #${po.poNumber} approved');
          }),
          const SizedBox(width: 8),
          _btn(t, 'Reject', AppColors.error, false, () {
            n.reject(po.id);
            toast('PO #${po.poNumber} rejected');
          }),
        ];
      case POStatus.approved:
        return [
          _btn(t, 'Mark Dispatched', const Color(0xFF8B5CF6), true, () {
            n.dispatch(po.id);
            toast('PO #${po.poNumber} dispatched');
          }),
        ];
      case POStatus.dispatched:
        return [
          _btn(t, 'Receive Goods → Stock', AppColors.success, true, () {
            n.receive(po.id);
            toast('Received PO #${po.poNumber} — inventory updated');
          }),
        ];
      case POStatus.received:
        return [
          Row(children: [
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            Text('Received — stock updated',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
          ]),
        ];
      case POStatus.rejected:
        return [
          Text('Rejected',
              style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        ];
    }
  }

  Widget _btn(AppTones t, String label, Color color, bool filled,
      VoidCallback onTap) {
    return SizedBox(
      height: 34,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ),
    );
  }
}

// =============================================================================
// CREATE PO FORM
// =============================================================================

class _CreatePOSheet extends ConsumerStatefulWidget {
  const _CreatePOSheet();

  static Future<void> show(BuildContext context) => showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => const _CreatePOSheet(),
      );

  @override
  ConsumerState<_CreatePOSheet> createState() => _CreatePOSheetState();
}

class _CreatePOSheetState extends ConsumerState<_CreatePOSheet> {
  String _supplier = kPoSuppliers.first;
  StockItem? _item;
  final _qty = TextEditingController();
  final List<POLine> _lines = [];
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _addLine(List<StockItem> stock) {
    final item = _item ?? (stock.isNotEmpty ? stock.first : null);
    final q = double.tryParse(_qty.text.trim());
    if (item == null || q == null || q <= 0) {
      setState(() => _error = 'Pick an item and a valid quantity');
      return;
    }
    setState(() {
      _lines.add(POLine(
          itemId: item.id,
          name: item.name,
          unit: item.unit,
          quantity: q,
          unitCost: item.unitCost));
      _qty.clear();
      _error = null;
    });
  }

  void _create() {
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one line item');
      return;
    }
    ref.read(purchaseOrderProvider.notifier).createDraft(
          supplier: _supplier,
          lines: List.of(_lines),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final stock = ref.watch(stockItemsProvider);
    _item ??= stock.isNotEmpty ? stock.first : null;
    final total = _lines.fold(0.0, (s, l) => s + l.lineTotal);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.border))),
                child: Row(children: [
                  Text('New Purchase Order',
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
                      _label(t, 'Supplier'),
                      _dropdown<String>(
                        t,
                        value: _supplier,
                        items: kPoSuppliers,
                        text: (s) => s,
                        onChanged: (v) => setState(() => _supplier = v!),
                      ),
                      const SizedBox(height: 14),
                      _label(t, 'Add line item'),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: _dropdown<StockItem>(
                            t,
                            value: _item,
                            items: stock,
                            text: (s) => '${s.name} (${s.unit})',
                            onChanged: (v) => setState(() => _item = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 46,
                            child: TextField(
                              controller: _qty,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'))
                              ],
                              style: TextStyle(color: t.textPrimary),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Qty',
                                hintStyle: TextStyle(color: t.textMuted),
                                filled: true,
                                fillColor: t.surfaceAlt,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: t.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.accent, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => _addLine(stock),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.surfaceAlt,
                              foregroundColor: t.textPrimary,
                              elevation: 0,
                              side: BorderSide(color: t.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Icon(Icons.add, size: 18),
                          ),
                        ),
                      ]),
                      if (_lines.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        for (int i = 0; i < _lines.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: t.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: t.border),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(_lines[i].name,
                                    style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5)),
                              ),
                              Text(_lines[i].qtyLabel,
                                  style: TextStyle(
                                      color: t.textMuted, fontSize: 12.5)),
                              const SizedBox(width: 14),
                              Text('\$${_lines[i].lineTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: t.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _lines.removeAt(i)),
                                child: Icon(Icons.close,
                                    size: 16,
                                    color: AppColors.error
                                        .withValues(alpha: 0.8)),
                              ),
                            ]),
                          ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.error_outline,
                              size: 15, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12.5)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.border))),
                child: Row(children: [
                  Text('Total: \$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const Spacer(),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Create Draft PO',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      );

  Widget _dropdown<T>(AppTones t,
      {required T? value,
      required List<T> items,
      required String Function(T) text,
      required ValueChanged<T?> onChanged}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: t.surface,
          icon: Icon(Icons.expand_more, color: t.textMuted),
          style: TextStyle(color: t.textPrimary, fontSize: 13.5),
          items: [
            for (final it in items)
              DropdownMenuItem<T>(value: it, child: Text(text(it))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
