import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/stock_models.dart';
import '../providers/stock_provider.dart';

/// SCREENS 29–31 — Stock Add / Adjust / Wastage. A single audited movement form
/// with an Adjustment Type switcher and a Wastage reason tag.
class StockMovementSheet extends ConsumerStatefulWidget {
  const StockMovementSheet({super.key, required this.itemId, this.initial});
  final String itemId;
  final MovementType? initial;

  static Future<void> show(BuildContext context, String itemId,
      {MovementType? initial}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => StockMovementSheet(itemId: itemId, initial: initial),
    );
  }

  @override
  ConsumerState<StockMovementSheet> createState() => _StockMovementSheetState();
}

enum _Mode { add, adjust, wastage }

class _StockMovementSheetState extends ConsumerState<StockMovementSheet> {
  late _Mode _mode;
  final _qty = TextEditingController();
  final _note = TextEditingController();
  WastageReason _reason = WastageReason.spoilage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.initial) {
      MovementType.wastage => _Mode.wastage,
      MovementType.adjustment => _Mode.adjust,
      _ => _Mode.add,
    };
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit(StockItem item) {
    setState(() => _error = null);
    final v = double.tryParse(_qty.text.trim());
    if (v == null || v < 0) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }
    final c = ref.read(stockControllerProvider.notifier);
    switch (_mode) {
      case _Mode.add:
        if (v <= 0) return setState(() => _error = 'Quantity must be > 0');
        c.addStock(item.id, v, note: _note.text.trim().isEmpty ? null : _note.text.trim());
        break;
      case _Mode.adjust:
        c.adjustTo(item.id, v, note: _note.text.trim().isEmpty ? null : _note.text.trim());
        break;
      case _Mode.wastage:
        if (v <= 0) return setState(() => _error = 'Quantity must be > 0');
        c.recordWastage(item.id, v, _reason,
            note: _note.text.trim().isEmpty ? null : _note.text.trim());
        break;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final item = ref.watch(stockItemsProvider).firstWhere(
        (e) => e.id == widget.itemId,
        orElse: () => ref.read(stockItemsProvider).first);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(t, item),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modeTabs(t),
                    const SizedBox(height: 16),
                    _label(t, _mode == _Mode.adjust
                        ? 'Counted quantity (${item.unit})'
                        : 'Quantity (${item.unit})'),
                    _input(t, _qty, '0'),
                    if (_mode == _Mode.adjust) ...[
                      const SizedBox(height: 8),
                      Text('Current on hand: ${item.quantityLabel}',
                          style: TextStyle(color: t.textMuted, fontSize: 12)),
                    ],
                    if (_mode == _Mode.wastage) ...[
                      const SizedBox(height: 14),
                      _label(t, 'Reason'),
                      _reasonPicker(t),
                    ],
                    const SizedBox(height: 14),
                    _label(t, 'Audit note (optional)'),
                    _input(t, _note, 'Reference / remark…'),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.error_outline,
                            size: 15, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12.5)),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _submit(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mode == _Mode.wastage
                              ? AppColors.error
                              : AppColors.accent,
                          foregroundColor: _mode == _Mode.wastage
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(_ctaLabel(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ctaLabel() => switch (_mode) {
        _Mode.add => 'Add Stock',
        _Mode.adjust => 'Save Adjustment',
        _Mode.wastage => 'Record Wastage',
      };

  Widget _header(AppTones t, StockItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock Movement',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text('${item.name} · ${item.sku}',
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
            height: 38,
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
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        tab(_Mode.add, 'Add', Icons.add),
        tab(_Mode.adjust, 'Adjust', Icons.tune),
        tab(_Mode.wastage, 'Wastage', Icons.delete_sweep),
      ]),
    );
  }

  Widget _reasonPicker(AppTones t) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in WastageReason.values)
          GestureDetector(
            onTap: () => setState(() => _reason = r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _reason == r
                    ? AppColors.error.withValues(alpha: 0.14)
                    : t.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _reason == r ? AppColors.error : t.border),
              ),
              child: Text(r.label,
                  style: TextStyle(
                      color: _reason == r ? AppColors.error : t.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5)),
            ),
          ),
      ],
    );
  }

  Widget _label(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      );

  Widget _input(AppTones t, TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: c == _qty
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: TextStyle(color: t.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
