import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../cart/domain/models/cart_item_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/pos_providers.dart';

/// SCREEN 12 — Split Bill. Interactive calculator supporting three structural
/// strategies: by person count, by selected items, and by percentage shares.
class SplitBillSheet extends ConsumerStatefulWidget {
  const SplitBillSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const SplitBillSheet(),
    );
  }

  @override
  ConsumerState<SplitBillSheet> createState() => _SplitBillSheetState();
}

enum _Mode { persons, items, percentage }

class _SplitBillSheetState extends ConsumerState<SplitBillSheet> {
  _Mode _mode = _Mode.persons;

  // Persons.
  int _persons = 2;

  // Items.
  final Set<String> _selected = {};

  // Percentage.
  final List<TextEditingController> _pct = [
    TextEditingController(text: '50'),
    TextEditingController(text: '50'),
  ];

  @override
  void dispose() {
    for (final c in _pct) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final cart = ref.watch(cartProvider);
    final total = ref.watch(billProvider).grandTotal;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(t, total),
              _modeTabs(t),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_mode),
                      child: _body(t, cart, total),
                    ),
                  ),
                ),
              ),
              _footer(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppTones t, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Split Bill',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              Text('Total due  \$${total.toStringAsFixed(2)}',
                  style: TextStyle(color: t.textMuted, fontSize: 12.5)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: t.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _modeTabs(AppTones t) {
    Widget tab(_Mode m, String label, IconData icon) {
      final sel = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = m),
          child: Container(
            margin: const EdgeInsets.all(4),
            height: 40,
            decoration: BoxDecoration(
              color: sel ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15, color: sel ? Colors.white : t.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: sel ? Colors.white : t.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          tab(_Mode.persons, 'Persons', Icons.groups_outlined),
          tab(_Mode.items, 'Items', Icons.checklist),
          tab(_Mode.percentage, 'Percent', Icons.percent),
        ],
      ),
    );
  }

  Widget _body(AppTones t, List<CartItemModel> cart, double total) {
    switch (_mode) {
      case _Mode.persons:
        return _personsBody(t, total);
      case _Mode.items:
        return _itemsBody(t, cart, total);
      case _Mode.percentage:
        return _percentageBody(t, total);
    }
  }

  // --- By person count -------------------------------------------------------
  Widget _personsBody(AppTones t, double total) {
    final per = total / _persons;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepBtn(t, Icons.remove,
                () => setState(() => _persons = (_persons - 1).clamp(2, 20))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  Text('$_persons',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900)),
                  Text('people', style: TextStyle(color: t.textMuted, fontSize: 12)),
                ],
              ),
            ),
            _stepBtn(t, Icons.add,
                () => setState(() => _persons = (_persons + 1).clamp(2, 20))),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Text('Each person pays',
                  style: TextStyle(color: t.textSecondary, fontSize: 14)),
              const Spacer(),
              Text('\$${per.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 1; i <= _persons; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: Text('P$i · \$${per.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ),
          ],
        ),
      ],
    );
  }

  // --- By selected items -----------------------------------------------------
  Widget _itemsBody(AppTones t, List<CartItemModel> cart, double total) {
    final subtotal = cart.fold(0.0, (s, c) => s + c.total);
    final selectedSub = cart
        .where((c) => _selected.contains(c.id))
        .fold(0.0, (s, c) => s + c.total);
    // Selected share scaled to the grand total (taxes/charges included).
    final selectedShare = subtotal == 0 ? 0.0 : total * (selectedSub / subtotal);
    final remaining = total - selectedShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select items for this guest',
            style: TextStyle(color: t.textMuted, fontSize: 12.5)),
        const SizedBox(height: 10),
        for (final c in cart)
          GestureDetector(
            onTap: () => setState(() {
              if (!_selected.add(c.id)) _selected.remove(c.id);
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selected.contains(c.id)
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : t.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _selected.contains(c.id)
                        ? AppColors.accent
                        : t.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _selected.contains(c.id)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: _selected.contains(c.id)
                        ? AppColors.accent
                        : t.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${c.quantity}× ${c.menuItem.name}',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5)),
                  ),
                  Text('\$${c.total.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        _splitResultRow(t, 'This guest pays', selectedShare,
            highlight: true),
        const SizedBox(height: 8),
        _splitResultRow(t, 'Remaining for others', remaining),
      ],
    );
  }

  // --- By percentage ---------------------------------------------------------
  Widget _percentageBody(AppTones t, double total) {
    double sum = 0;
    for (final c in _pct) {
      sum += double.tryParse(c.text) ?? 0;
    }
    final balanced = (sum - 100).abs() < 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _pct.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border),
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _pct[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        color: t.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
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
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '\$${(total * ((double.tryParse(_pct[i].text) ?? 0) / 100)).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ),
                if (_pct.length > 2)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        size: 18, color: AppColors.error),
                    onPressed: () => setState(() => _pct.removeAt(i).dispose()),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _pct.length < 6
              ? () => setState(
                  () => _pct.add(TextEditingController(text: '0')))
              : null,
          icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
          label: const Text('Add party',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: (balanced ? AppColors.success : AppColors.warning)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: (balanced ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(balanced ? Icons.check_circle : Icons.error_outline,
                  size: 16,
                  color: balanced ? AppColors.success : AppColors.warning),
              const SizedBox(width: 8),
              Text(
                  balanced
                      ? 'Shares total 100%'
                      : 'Shares total ${sum.toStringAsFixed(0)}% — must equal 100%',
                  style: TextStyle(
                      color: balanced ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _splitResultRow(AppTones t, String label, double value,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.10)
            : t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlight ? AppColors.accent.withValues(alpha: 0.4) : t.border),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: t.textSecondary, fontSize: 14)),
          const Spacer(),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                  color: highlight ? AppColors.accent : t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _stepBtn(AppTones t, IconData icon, VoidCallback onTap) {
    return Material(
      color: t.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, size: 20, color: t.textPrimary),
        ),
      ),
    );
  }

  Widget _footer(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Done',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ),
    );
  }
}
