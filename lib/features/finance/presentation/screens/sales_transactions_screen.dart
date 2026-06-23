import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../pos/domain/models/pos_models.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../../../pos/presentation/widgets/receipt_modal.dart';

/// Clean Sales & Transactions ledger wired to the live order repository —
/// proper bill numbers, payment method, status and reprintable receipts.
class SalesTransactionsScreen extends ConsumerStatefulWidget {
  const SalesTransactionsScreen({super.key});

  @override
  ConsumerState<SalesTransactionsScreen> createState() =>
      _SalesTransactionsScreenState();
}

class _SalesTransactionsScreenState
    extends ConsumerState<SalesTransactionsScreen> {
  String _range = 'Today';
  String _query = '';

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

  String _route(OrderRecord o) =>
      o.orderType == OrderType.dineIn && o.tableName != null
          ? 'Table ${o.tableName}'
          : o.orderType.label;

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final all = ref.watch(orderRepositoryProvider);
    final q = _query.trim().toLowerCase();
    final orders = q.isEmpty
        ? all
        : all
            .where((o) =>
                '#${o.billNumber}'.contains(q) ||
                _route(o).toLowerCase().contains(q) ||
                (o.payment?.methodLabel ?? '').toLowerCase().contains(q))
            .toList();

    final sales = all.fold(0.0, (s, o) => s + o.breakdown.grandTotal);
    final avg = all.isEmpty ? 0.0 : sales / all.length;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales & Transactions',
                          style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('Payments, receipts and settlement history.',
                          style: TextStyle(color: t.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 280,
                  height: 44,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: t.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon:
                          Icon(Icons.search, size: 18, color: t.textMuted),
                      hintText: 'Search receipt / table / payment…',
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
            const SizedBox(height: 18),
            // KPI cards.
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Total Sales', _money(sales),
                  Icons.payments_outlined, AppColors.success),
              _kpi(t, 'Orders', '${all.length}',
                  Icons.receipt_long_outlined, AppColors.info),
              _kpi(t, 'Avg Ticket', _money(avg), Icons.trending_up,
                  AppColors.accent),
              _kpi(t, 'Refunds', '0', Icons.undo, AppColors.warning),
            ]),
            const SizedBox(height: 18),
            // Range tabs.
            Row(children: [
              for (final r in ['Today', 'Week', 'Month'])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _range = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: _range == r ? AppColors.accent : t.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _range == r ? AppColors.accent : t.border),
                      ),
                      child: Text(r,
                          style: TextStyle(
                              color: _range == r ? Colors.white : t.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            // Table.
            Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                      color: t.surfaceAlt,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7))),
                  child: Row(children: [
                    Expanded(flex: 2, child: _h(t, 'RECEIPT')),
                    Expanded(flex: 3, child: _h(t, 'TABLE / TYPE')),
                    Expanded(flex: 2, child: _h(t, 'PAYMENT')),
                    Expanded(flex: 2, child: _h(t, 'TIME')),
                    Expanded(flex: 2, child: _h(t, 'STATUS')),
                    Expanded(flex: 2, child: _h(t, 'TOTAL')),
                    const SizedBox(width: 44),
                  ]),
                ),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text('No transactions yet — generate a bill in POS',
                          style: TextStyle(color: t.textMuted, fontSize: 13)),
                    ),
                  )
                else
                  for (int i = 0; i < orders.length; i++)
                    _row(t, orders[i], i == orders.length - 1),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
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

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));

  Widget _row(AppTones t, OrderRecord o, bool last) {
    final paid = o.payment != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text('#${o.billNumber}',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5)),
        ),
        Expanded(
          flex: 3,
          child: Row(children: [
            Icon(o.orderType.icon, size: 14, color: t.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(_route(o),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(o.payment?.methodLabel ?? '—',
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
        ),
        Expanded(
          flex: 2,
          child: Text(_time(o.createdAt),
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: (paid ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(paid ? 'Paid' : 'Unbilled',
                  style: TextStyle(
                      color: paid ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(_money(o.breakdown.grandTotal),
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
        SizedBox(
          width: 44,
          child: IconButton(
            icon: Icon(Icons.visibility_outlined,
                size: 18, color: AppColors.accent),
            tooltip: 'View receipt',
            onPressed: () => ReceiptModal.show(context, o),
          ),
        ),
      ]),
    );
  }
}
