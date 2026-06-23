import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/stock_models.dart';
import '../providers/stock_provider.dart';

/// SCREEN 32 — Inventory Transfer. Moves stock from a source branch to a
/// destination branch, logging an audited transfer movement.
class StockTransferSheet extends ConsumerStatefulWidget {
  const StockTransferSheet({super.key, required this.itemId});
  final String itemId;

  static Future<void> show(BuildContext context, String itemId) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => StockTransferSheet(itemId: itemId),
    );
  }

  @override
  ConsumerState<StockTransferSheet> createState() =>
      _StockTransferSheetState();
}

class _StockTransferSheetState extends ConsumerState<StockTransferSheet> {
  final _qty = TextEditingController();
  String _from = kBranches.first;
  String _to = kBranches[1];
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _submit(StockItem item) {
    setState(() => _error = null);
    final v = double.tryParse(_qty.text.trim());
    if (v == null || v <= 0) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }
    if (v > item.quantity) {
      setState(() => _error = 'Cannot transfer more than on hand');
      return;
    }
    if (_from == _to) {
      setState(() => _error = 'Source and destination must differ');
      return;
    }
    ref.read(stockControllerProvider.notifier).transfer(item.id, v, _from, _to);
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
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.border))),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inventory Transfer',
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('${item.name} · on hand ${item.quantityLabel}',
                            style:
                                TextStyle(color: t.textMuted, fontSize: 12.5)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: t.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _branch(t, 'From Branch', _from,
                            (v) => setState(() => _from = v))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward,
                              color: AppColors.accent, size: 20),
                        ),
                        Expanded(child: _branch(t, 'To Branch', _to,
                            (v) => setState(() => _to = v))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label(t, 'Quantity (${item.unit})'),
                    TextField(
                      controller: _qty,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      style: TextStyle(color: t.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(color: t.textMuted),
                        filled: true,
                        fillColor: t.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
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
                      child: ElevatedButton.icon(
                        onPressed: () => _submit(item),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Transfer Stock',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _branch(
      AppTones t, String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t, label),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: t.surface,
              icon: Icon(Icons.expand_more, color: t.textMuted),
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600),
              items: [
                for (final b in kBranches)
                  DropdownMenuItem<String>(value: b, child: Text(b)),
              ],
              onChanged: (v) => onChanged(v ?? value),
            ),
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
}
