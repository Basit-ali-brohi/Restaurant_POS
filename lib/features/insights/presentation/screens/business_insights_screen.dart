import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../pos/domain/models/pos_models.dart';
import '../../../pos/presentation/providers/pos_providers.dart';

/// SCREEN — Business Insights (clean rebuild). Live analytics from the order
/// repository: KPI cards, revenue by channel, payment mix and top sellers.
class BusinessInsightsScreen extends ConsumerStatefulWidget {
  const BusinessInsightsScreen({super.key});

  @override
  ConsumerState<BusinessInsightsScreen> createState() =>
      _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState
    extends ConsumerState<BusinessInsightsScreen> {
  String _range = 'Today';

  static String _money(double v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return 'PKR $b';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final orders = ref.watch(orderRepositoryProvider);

    final revenue = orders.fold(0.0, (s, o) => s + o.breakdown.grandTotal);
    final avg = orders.isEmpty ? 0.0 : revenue / orders.length;

    // Revenue by channel.
    final byChannel = <OrderType, double>{
      for (final ty in OrderType.values)
        ty: orders
            .where((o) => o.orderType == ty)
            .fold(0.0, (s, o) => s + o.breakdown.grandTotal)
    };
    final maxChannel = byChannel.values.isEmpty
        ? 1.0
        : (byChannel.values.reduce((a, b) => a > b ? a : b)).clamp(1.0, double.infinity);

    // Payment mix.
    final byMethod = <PaymentMethod, double>{
      for (final m in PaymentMethod.values) m: 0.0
    };
    for (final o in orders) {
      for (final tender in o.payment?.tenders ?? const []) {
        byMethod[tender.method] = (byMethod[tender.method] ?? 0) + tender.amount;
      }
    }
    final paymentTotal = byMethod.values.fold(0.0, (s, v) => s + v);

    // Top sellers.
    final qty = <String, int>{};
    final rev = <String, double>{};
    for (final o in orders) {
      for (final l in o.lines) {
        qty[l.name] = (qty[l.name] ?? 0) + l.quantity;
        rev[l.name] = (rev[l.name] ?? 0) + l.lineTotal;
      }
    }
    final top = qty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxQty = top.isEmpty ? 1 : top.first.value;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Business Insights',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              _rangeTabs(t),
            ]),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Total Revenue', _money(revenue), Icons.trending_up,
                  AppColors.success),
              _kpi(t, 'Total Orders', '${orders.length}',
                  Icons.receipt_long_outlined, AppColors.info),
              _kpi(t, 'Avg Ticket', _money(avg), Icons.confirmation_number_outlined,
                  AppColors.accent),
              _kpi(t, 'Avg Prep Time', '14 min', Icons.timer_outlined,
                  AppColors.warning),
            ]),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 980;
              final channel = _RevenueByChannel(
                  tones: t, data: byChannel, max: maxChannel, money: _money);
              final payment = _PaymentMix(
                  tones: t, data: byMethod, total: paymentTotal, money: _money);
              if (stacked) {
                return Column(children: [
                  SizedBox(height: 240, child: channel),
                  const SizedBox(height: 16),
                  SizedBox(height: 240, child: payment),
                ]);
              }
              return SizedBox(
                height: 260,
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 3, child: channel),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: payment),
                ]),
              );
            }),
            const SizedBox(height: 20),
            _TopSellers(tones: t, top: top, rev: rev, maxQty: maxQty),
          ],
        ),
      ),
    );
  }

  Widget _rangeTabs(AppTones t) {
    Widget chip(String r) {
      final sel = _range == r;
      return GestureDetector(
        onTap: () => setState(() => _range = r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6)),
          child: Text(r,
              style: TextStyle(
                  color: sel ? Colors.white : t.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.border)),
      child: Row(children: [chip('Today'), chip('Week'), chip('Month')]),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint) {
    return Container(
      width: 240,
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
}

class _Panel extends StatelessWidget {
  const _Panel({required this.tones, required this.title, required this.child});
  final AppTones tones;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Text(title,
              style: TextStyle(
                  color: tones.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Divider(height: 1, color: tones.border),
        Expanded(child: child),
      ]),
    );
  }
}

class _RevenueByChannel extends StatelessWidget {
  const _RevenueByChannel(
      {required this.tones,
      required this.data,
      required this.max,
      required this.money});
  final AppTones tones;
  final Map<OrderType, double> data;
  final double max;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      tones: tones,
      title: 'Revenue by Channel',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ty in OrderType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(ty.icon, size: 15, color: tones.textSecondary),
                    const SizedBox(width: 6),
                    Text(ty.label,
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const Spacer(),
                    Text(money(data[ty] ?? 0),
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((data[ty] ?? 0) / max).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: tones.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMix extends StatelessWidget {
  const _PaymentMix(
      {required this.tones,
      required this.data,
      required this.total,
      required this.money});
  final AppTones tones;
  final Map<PaymentMethod, double> data;
  final double total;
  final String Function(double) money;

  static const _colors = [AppColors.success, AppColors.info, Color(0xFF8B5CF6)];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      tones: tones,
      title: 'Payment Mix',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (total == 0)
              Center(
                child: Text('No payments yet',
                    style: TextStyle(color: tones.textMuted, fontSize: 13)),
              )
            else
              for (int i = 0; i < PaymentMethod.values.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: _colors[i % _colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(PaymentMethod.values[i].label,
                        style: TextStyle(
                            color: tones.textPrimary, fontSize: 13)),
                    const Spacer(),
                    Text(
                        '${((data[PaymentMethod.values[i]] ?? 0) / total * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: tones.textMuted, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text(money(data[PaymentMethod.values[i]] ?? 0),
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
          ],
        ),
      ),
    );
  }
}

class _TopSellers extends StatelessWidget {
  const _TopSellers(
      {required this.tones,
      required this.top,
      required this.rev,
      required this.maxQty});
  final AppTones tones;
  final List<MapEntry<String, int>> top;
  final Map<String, double> rev;
  final int maxQty;

  @override
  Widget build(BuildContext context) {
    final items = top.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Text('Top Sellers',
              style: TextStyle(
                  color: tones.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Divider(height: 1, color: tones.border),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
                child: Text('No sales yet',
                    style: TextStyle(color: tones.textMuted, fontSize: 13))),
          )
        else
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: i == 0 ? AppColors.accent : tones.surfaceAlt,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: i == 0 ? Colors.white : tones.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: Text(items[i].key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: tones.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (items[i].value / maxQty).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: tones.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${items[i].value} sold',
                    style: TextStyle(color: tones.textMuted, fontSize: 12)),
                const SizedBox(width: 14),
                Text(
                    'PKR ${(rev[items[i].key] ?? 0).round()}',
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
      ]),
    );
  }
}
