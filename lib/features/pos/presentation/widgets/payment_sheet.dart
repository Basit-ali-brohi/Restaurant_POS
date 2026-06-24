import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../../../kitchen/presentation/providers/orders_history_provider.dart';
import '../../../kitchen/domain/models/order_model.dart' as kds;
import '../../../dashboard/presentation/providers/sales_provider.dart';
import '../../domain/models/pos_models.dart';
import '../providers/pos_providers.dart';

/// SCREENS 13–14 — Payment. Validates one or more tenders (Cash, Card, Mobile
/// Wallet), computes change, then commits the order to the local repository and
/// returns the finalised [OrderRecord] for the receipt.
class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key});

  /// Returns the committed [OrderRecord] on success, or null if cancelled.
  static Future<OrderRecord?> show(BuildContext context) {
    return showDialog<OrderRecord>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const PaymentSheet(),
    );
  }

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final List<TenderLine> _tenders = [];
  PaymentMethod _method = PaymentMethod.cash;
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _total => ref.read(billProvider).grandTotal;
  double get _paid => _tenders.fold(0.0, (s, t) => s + t.amount);
  double get _remaining => (_total - _paid).clamp(0, double.infinity);
  double get _change => (_paid - _total).clamp(0, double.infinity);
  bool get _settled => _paid + 0.001 >= _total && _tenders.isNotEmpty;

  void _addTender(double amount) {
    if (amount <= 0) return;
    setState(() {
      _tenders.add(TenderLine(_method, amount));
      _amount.clear();
    });
  }

  void _complete() {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || !_settled) return;
    final type = ref.read(orderTypeProvider);
    final table = ref.read(selectedTableNameProvider);
    final breakdown = ref.read(billProvider);

    final payment = PaymentInfo(
      tenders: List.unmodifiable(_tenders),
      total: _total,
      tendered: _paid,
      change: _change,
    );

    final record = ref.read(orderRepositoryProvider.notifier).commitOrder(
          cart: cart,
          type: type,
          tableName: type == OrderType.dineIn ? table : null,
          breakdown: breakdown,
          payment: payment,
        );

    final label =
        type == OrderType.dineIn ? (table ?? 'Walk-in') : 'Takeaway';

    // Mirror the paid order into the kitchen timeline so it appears in Orders
    // History as a completed ticket.
    final kdsOrder = kds.OrderModel(
      id: record.id,
      tableName: label,
      items: cart,
      status: kds.OrderStatus.completed,
      timestamp: DateTime.now(),
      orderType: type == OrderType.dineIn
          ? kds.OrderType.dineIn
          : kds.OrderType.takeaway,
    );
    final timeline = ref.read(ordersTimelineProvider.notifier);
    timeline.logCreated(kdsOrder);
    timeline.logCompleted(kdsOrder);

    // Record the sale (marks the order PAID in history + Sales screen).
    final cash = _tenders
        .where((t) => t.method == PaymentMethod.cash)
        .fold(0.0, (s, t) => s + t.amount);
    final card = _tenders
        .where((t) => t.method != PaymentMethod.cash)
        .fold(0.0, (s, t) => s + t.amount);
    ref.read(salesProvider.notifier).addSale(TransactionModel(
          id: record.id,
          tableLabel: label,
          paymentMethod: _method.label,
          total: breakdown.grandTotal,
          time: DateTime.now(),
          status: TransactionStatus.paid,
          cashAmount: cash,
          cardAmount: card,
        ));

    if (type == OrderType.dineIn && table != null) {
      ref.read(tableProvider.notifier).seatTable(table, orderId: record.id);
    }

    ref.read(cartProvider.notifier).clear();
    ref.read(discountProvider.notifier).state = 0;
    ref.read(selectedTableNameProvider.notifier).state = null;

    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final total = ref.watch(billProvider).grandTotal;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summary(t, total),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _methodSelector(t),
                      const SizedBox(height: 16),
                      _amountEntry(t),
                      if (_tenders.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _tenderList(t),
                      ],
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

  Widget _summary(AppTones t, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Payment',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: t.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _summaryCell(t, 'Total Due', total, t.textPrimary),
              _summaryCell(t, 'Paid', _paid, AppColors.info),
              _change > 0
                  ? _summaryCell(t, 'Change', _change, AppColors.success)
                  : _summaryCell(t, 'Remaining', _remaining, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(AppTones t, String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text('PKR ${value.toStringAsFixed(2)}',
              style: TextStyle(
                  color: color, fontSize: 19, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _methodSelector(AppTones t) {
    return Row(
      children: [
        for (final m in PaymentMethod.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _method = m),
              child: Container(
                height: 76,
                margin: EdgeInsets.only(
                    right: m == PaymentMethod.values.last ? 0 : 10),
                decoration: BoxDecoration(
                  color: _method == m
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : t.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _method == m ? AppColors.accent : t.border,
                      width: _method == m ? 1.6 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m.icon,
                        size: 24,
                        color:
                            _method == m ? AppColors.accent : t.textSecondary),
                    const SizedBox(height: 6),
                    Text(m.label,
                        style: TextStyle(
                            color: _method == m
                                ? t.textPrimary
                                : t.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountEntry(AppTones t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tender amount (${_method.label})',
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: 'PKR ',
                  prefixStyle: TextStyle(
                      color: t.textMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: t.textMuted),
                  filled: true,
                  fillColor: t.surfaceAlt,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: t.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(_amount.text) ?? 0;
                  _addTender(v);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.surfaceAlt,
                  foregroundColor: t.textPrimary,
                  elevation: 0,
                  side: BorderSide(color: t.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickChip(t, 'Exact', () => _addTender(_remaining)),
            for (final v in [10.0, 20.0, 50.0, 100.0])
              _quickChip(t, '+PKR ${v.toStringAsFixed(0)}', () => _addTender(v)),
          ],
        ),
      ],
    );
  }

  Widget _quickChip(AppTones t, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }

  Widget _tenderList(AppTones t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TENDERS',
            style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
        const SizedBox(height: 8),
        for (int i = 0; i < _tenders.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(_tenders[i].method.icon,
                    size: 18, color: t.textSecondary),
                const SizedBox(width: 10),
                Text(_tenders[i].method.label,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5)),
                const Spacer(),
                Text('PKR ${_tenders[i].amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _tenders.removeAt(i)),
                  child: Icon(Icons.close,
                      size: 16,
                      color: AppColors.error.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _footer(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _settled ? _complete : null,
          icon: const Icon(Icons.check_circle, size: 20),
          label: Text(
            _settled
                ? (_change > 0
                    ? 'Complete · Change PKR ${_change.toStringAsFixed(2)}'
                    : 'Complete Payment')
                : 'Pay PKR ${_remaining.toStringAsFixed(2)} more',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: t.border,
            disabledForegroundColor: t.textMuted,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
