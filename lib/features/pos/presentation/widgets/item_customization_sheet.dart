import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../menu/domain/models/menu_item_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/models/pos_models.dart';
import '../providers/pos_providers.dart';

/// Overlay dialog presenting a menu item's variations (single-select) and
/// modifier tags (multi-select). Selections recompute the effective unit price
/// live and, on confirm, push a fully-configured line into the active bill.
class ItemCustomizationSheet extends ConsumerStatefulWidget {
  const ItemCustomizationSheet({super.key, required this.item});

  final MenuItemModel item;

  static Future<void> show(BuildContext context, MenuItemModel item) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => ItemCustomizationSheet(item: item),
    );
  }

  @override
  ConsumerState<ItemCustomizationSheet> createState() =>
      _ItemCustomizationSheetState();
}

class _ItemCustomizationSheetState
    extends ConsumerState<ItemCustomizationSheet> {
  late final ProductOptionConfig _config;
  int _variationIndex = 0;
  final Set<int> _modifierIndexes = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _config = optionsForItem(widget.item);
  }

  double get _variationDelta =>
      _config.hasVariations ? _config.variations[_variationIndex].priceDelta : 0;

  double get _modifierDelta => _modifierIndexes.fold(
        0.0,
        (sum, i) => sum + _config.modifiers[i].priceDelta,
      );

  // Honour time-based "Happy Hour" pricing (SRS 5.x) when the window is live.
  double get _unitPrice =>
      widget.item.effectivePrice() + _variationDelta + _modifierDelta;

  String? get _variationLabel =>
      _config.hasVariations ? _config.variations[_variationIndex].label : null;

  List<String> get _modifierLabels =>
      _modifierIndexes.map((i) => _config.modifiers[i].label).toList();

  void _addToBill() {
    ref.read(cartProvider.notifier).addConfigured(
          item: widget.item,
          variation: _variationLabel,
          modifiers: _modifierLabels,
          unitPrice: _unitPrice,
          quantity: _quantity,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(t),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_config.hasVariations) ...[
                        _sectionLabel(t, 'VARIATION'),
                        _variationSelector(t),
                        const SizedBox(height: 18),
                      ],
                      if (_config.hasModifiers) ...[
                        _sectionLabel(t, 'MODIFIERS & INSTRUCTIONS'),
                        _modifierSelector(t),
                        const SizedBox(height: 8),
                      ],
                      if (!_config.isConfigurable)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No options for this item — add directly to the bill.',
                            style:
                                TextStyle(color: t.textMuted, fontSize: 13),
                          ),
                        ),
                    ],
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

  // --- Header -----------------------------------------------------------------
  Widget _header(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: t.surfaceAlt,
              image: DecorationImage(
                image: NetworkImage(widget.item.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                const SizedBox(height: 2),
                Text('Base \$${widget.item.price.toStringAsFixed(2)}',
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: t.textMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppTones t, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text(text,
          style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }

  // --- Variations (single select) --------------------------------------------
  Widget _variationSelector(AppTones t) {
    return Column(
      children: [
        for (int i = 0; i < _config.variations.length; i++)
          _variationRow(t, i, _config.variations[i]),
      ],
    );
  }

  Widget _variationRow(AppTones t, int index, ProductVariation v) {
    final selected = _variationIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _variationIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : t.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.accent : t.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v.label,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14)),
            ),
            Text(
              v.priceDelta == 0
                  ? 'Included'
                  : '+\$${v.priceDelta.toStringAsFixed(2)}',
              style: TextStyle(
                  color: v.priceDelta == 0 ? t.textMuted : AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modifiers (multi select chips) ----------------------------------------
  Widget _modifierSelector(AppTones t) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int i = 0; i < _config.modifiers.length; i++)
          _modifierChip(t, i, _config.modifiers[i]),
      ],
    );
  }

  Widget _modifierChip(AppTones t, int index, ModifierOption m) {
    final selected = _modifierIndexes.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _modifierIndexes.remove(index);
        } else {
          _modifierIndexes.add(index);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : t.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 16, color: selected ? AppColors.accent : t.textMuted),
            const SizedBox(width: 8),
            Text(m.label,
                style: TextStyle(
                    color: selected ? t.textPrimary : t.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13)),
            if (m.isPaid) ...[
              const SizedBox(width: 6),
              Text('+\$${m.priceDelta.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // --- Footer: quantity stepper + add ----------------------------------------
  Widget _footer(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          _qtyButton(t, Icons.remove, () {
            if (_quantity > 1) setState(() => _quantity--);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_quantity',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          _qtyButton(t, Icons.add, () => setState(() => _quantity++)),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _addToBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        'Add  •  \$${(_unitPrice * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(AppTones t, IconData icon, VoidCallback onTap) {
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, size: 18, color: t.textPrimary),
        ),
      ),
    );
  }
}
