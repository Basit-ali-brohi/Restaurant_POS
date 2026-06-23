import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../menu/domain/models/menu_item_model.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../cart/domain/models/cart_item_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../../domain/models/pos_models.dart';
import '../providers/pos_providers.dart';
import '../widgets/item_customization_sheet.dart';
import '../widgets/pos_table_monitor.dart';
import '../widgets/payment_sheet.dart';
import '../widgets/split_bill_sheet.dart';
import '../widgets/receipt_modal.dart';

// =============================================================================
// POS COUNTER — master/detail checkout view
//   Left  : categorised menu grid (or the live floor map when binding a table)
//   Right : active bill cart with channel switcher + checkout pipeline
// =============================================================================

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final orderType = ref.watch(orderTypeProvider);
    final boundTable = ref.watch(selectedTableNameProvider);

    // Dine-In requires a bound table before ordering — show the floor first.
    final showFloor =
        orderType == OrderType.dineIn && boundTable == null;

    return Container(
      color: t.canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: showFloor ? const PosTableMonitor() : const _MenuPane(),
          ),
          Container(width: 1, color: t.border),
          SizedBox(width: 384, child: _BillPane(tones: t)),
        ],
      ),
    );
  }
}

// =============================================================================
// LEFT — MENU PANE
// =============================================================================

class _MenuPane extends ConsumerWidget {
  const _MenuPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final items = ref.watch(filteredMenuProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: t.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        ref.read(searchQueryProvider.notifier).state = v,
                    style: TextStyle(color: t.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search menu items…',
                      hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Category filter.
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final category = categories[i];
              final selected = category == selectedCategory;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedCategoryProvider.notifier).state = category;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected ? AppColors.accent : t.border),
                  ),
                  child: Text(category,
                      style: TextStyle(
                          color: selected ? Colors.white : t.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Grid.
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('No items match your search',
                      style: TextStyle(color: t.textMuted)),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    int cross = 2;
                    if (c.maxWidth > 560) cross = 3;
                    if (c.maxWidth > 880) cross = 4;
                    if (c.maxWidth > 1180) cross = 5;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          _MenuTile(tones: t, item: items[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.tones, required this.item});
  final AppTones tones;
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tones.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ItemCustomizationSheet.show(context, item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tones.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(item.image, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                                color: tones.surfaceAlt,
                                child: Icon(Icons.restaurant,
                                    color: tones.textMuted),
                              )),
                      if (item.isVeg)
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: _Dot(color: AppColors.success),
                        ),
                      if (item.isChefChoice || item.isBestSeller)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isChefChoice ? "CHEF'S" : 'POPULAR',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.isHappyHourActive()) ...[
                          Text('\$${item.effectivePrice().toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(width: 5),
                          Text('\$${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: tones.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough)),
                        ] else
                          Text('\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.add_circle,
                            color: AppColors.accent, size: 22),
                      ],
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
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// =============================================================================
// RIGHT — ACTIVE BILL PANE
// =============================================================================

class _BillPane extends ConsumerWidget {
  const _BillPane({required this.tones});
  final AppTones tones;

  void _setType(WidgetRef ref, OrderType type) {
    ref.read(orderTypeProvider.notifier).state = type;
    if (type != OrderType.dineIn) {
      ref.read(selectedTableNameProvider.notifier).state = null;
    }
  }

  /// Opens the payment screen; on a settled payment it commits the order and
  /// pops the thermal receipt. Commit/clear/seat all happen inside PaymentSheet.
  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    if (ref.read(cartProvider).isEmpty) return;
    final record = await PaymentSheet.show(context);
    if (record != null && context.mounted) {
      ReceiptModal.show(context, record);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final bill = ref.watch(billProvider);
    final orderType = ref.watch(orderTypeProvider);
    final boundTable = ref.watch(selectedTableNameProvider);

    final canCheckout = cart.isNotEmpty &&
        (orderType != OrderType.dineIn || boundTable != null);

    return Container(
      color: tones.surface,
      child: Column(
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Text('Active Bill',
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                if (cart.isNotEmpty)
                  GestureDetector(
                    onTap: () => ref.read(cartProvider.notifier).clear(),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: tones.textMuted),
                        const SizedBox(width: 4),
                        Text('Clear',
                            style: TextStyle(
                                color: tones.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Channel switcher.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ChannelSwitcher(
              tones: tones,
              active: orderType,
              onChanged: (type) => _setType(ref, type),
            ),
          ),
          // Bound table (dine-in).
          if (orderType == OrderType.dineIn)
            _BoundTableRow(
              tones: tones,
              tableName: boundTable,
              onChange: () =>
                  ref.read(selectedTableNameProvider.notifier).state = null,
            ),
          const SizedBox(height: 6),
          Divider(height: 1, color: tones.border),
          // Lines.
          Expanded(
            child: cart.isEmpty
                ? _emptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _CartLine(tones: tones, ref: ref, line: cart[i]),
                  ),
          ),
          // Breakdown + checkout.
          if (cart.isNotEmpty)
            _CheckoutFooter(
              tones: tones,
              bill: bill,
              canCheckout: canCheckout,
              orderType: orderType,
              onCheckout: () => _checkout(context, ref),
              onSplit: () => SplitBillSheet.show(context),
            ),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 44, color: tones.textMuted),
          const SizedBox(height: 12),
          Text('The bill is empty',
              style: TextStyle(
                  color: tones.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap a menu item to configure & add',
              style: TextStyle(color: tones.textMuted, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _ChannelSwitcher extends StatelessWidget {
  const _ChannelSwitcher(
      {required this.tones, required this.active, required this.onChanged});
  final AppTones tones;
  final OrderType active;
  final ValueChanged<OrderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tones.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Row(
        children: [
          for (final type in OrderType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  decoration: BoxDecoration(
                    color: active == type
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon,
                          size: 16,
                          color: active == type
                              ? Colors.black
                              : tones.textSecondary),
                      const SizedBox(width: 6),
                      Text(type.label,
                          style: TextStyle(
                              color: active == type
                                  ? Colors.black
                                  : tones.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoundTableRow extends StatelessWidget {
  const _BoundTableRow(
      {required this.tones, required this.tableName, required this.onChange});
  final AppTones tones;
  final String? tableName;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final bound = tableName != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bound
              ? AppColors.success.withValues(alpha: 0.10)
              : AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: (bound ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(bound ? Icons.table_restaurant : Icons.info_outline,
                size: 18,
                color: bound ? AppColors.success : AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bound ? 'Table $tableName' : 'Select a table from the floor',
                style: TextStyle(
                    color: tones.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            if (bound)
              GestureDetector(
                onTap: onChange,
                child: Text('Change',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine(
      {required this.tones, required this.ref, required this.line});
  final AppTones tones;
  final WidgetRef ref;
  final CartItemModel line;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (line.variation != null) line.variation!,
      ...line.modifiers,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tones.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(line.menuItem.name,
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Text('\$${line.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: tones.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(meta,
                style: TextStyle(color: tones.textMuted, fontSize: 11.5)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text('\$${line.unitPrice.toStringAsFixed(2)} ea',
                  style: TextStyle(color: tones.textMuted, fontSize: 12)),
              const Spacer(),
              _Stepper(
                tones: tones,
                quantity: line.quantity,
                onMinus: () => ref
                    .read(cartProvider.notifier)
                    .decrementQuantity(line.id),
                onPlus: () => ref
                    .read(cartProvider.notifier)
                    .incrementQuantity(line.id),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    ref.read(cartProvider.notifier).removeItem(line.id),
                child: Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.tones,
      required this.quantity,
      required this.onMinus,
      required this.onPlus});
  final AppTones tones;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tones.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tones.border),
            ),
            child: Icon(icon, size: 15, color: tones.textPrimary),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove, onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$quantity',
              style: TextStyle(
                  color: tones.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
        btn(Icons.add, onPlus),
      ],
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.tones,
    required this.bill,
    required this.canCheckout,
    required this.orderType,
    required this.onCheckout,
    required this.onSplit,
  });

  final AppTones tones;
  final BillBreakdown bill;
  final bool canCheckout;
  final OrderType orderType;
  final VoidCallback onCheckout;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: tones.surfaceAlt,
        border: Border(top: BorderSide(color: tones.border)),
      ),
      child: Column(
        children: [
          _row('Subtotal', bill.subtotal),
          if (bill.discount > 0) _row('Discount', -bill.discount),
          for (final tax in bill.taxes)
            _row('${tax.label} (${(tax.rate * 100).toStringAsFixed(1)}%)',
                tax.amount),
          if (bill.serviceCharge > 0) _row('Service (10%)', bill.serviceCharge),
          if (bill.packagingFee > 0) _row('Packaging', bill.packagingFee),
          if (bill.deliveryFee > 0) _row('Delivery', bill.deliveryFee),
          if (bill.roundOff != 0) _row('Round Off', bill.roundOff),
          const SizedBox(height: 8),
          Divider(height: 1, color: tones.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('TOTAL',
                  style: TextStyle(
                      color: tones.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const Spacer(),
              Text('\$${bill.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: canCheckout ? onSplit : null,
                    icon: Icon(Icons.call_split,
                        size: 18, color: tones.textSecondary),
                    label: Text('Split',
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tones.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canCheckout ? onCheckout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: tones.border,
                      disabledForegroundColor: tones.textMuted,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.point_of_sale, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          canCheckout
                              ? 'Pay Now'
                              : (orderType == OrderType.dineIn
                                  ? 'Select a Table'
                                  : 'Add Items'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value) {
    final negative = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: tones.textSecondary, fontSize: 13)),
          const Spacer(),
          Text('${negative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
              style: TextStyle(
                  color: tones.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
