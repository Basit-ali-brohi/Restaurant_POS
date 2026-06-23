import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';

class Branch {
  final String name;
  final String city;
  final double revenue;
  final int orders;
  final double avgTicket;
  final double growth; // fractional, +/-
  final double laborCostPct;
  final bool open;

  const Branch(this.name, this.city, this.revenue, this.orders, this.avgTicket,
      this.growth, this.laborCostPct, this.open);
}

final branchesProvider = Provider<List<Branch>>((ref) {
  return const [
    Branch('Main Dining', 'Lahore · Gulberg', 1842300, 4120, 447, 0.124, 0.245, true),
    Branch('Downtown Branch', 'Lahore · Mall Rd', 1235600, 3010, 410, 0.082, 0.268, true),
    Branch('Airport Kiosk', 'Lahore · Allama Iqbal', 684900, 2280, 300, -0.031, 0.221, true),
    Branch('Seaview Outlet', 'Karachi · Clifton', 1521000, 3460, 439, 0.156, 0.252, true),
    Branch('Capital Branch', 'Islamabad · F-7', 998200, 2540, 393, 0.044, 0.239, false),
  ];
});

/// SCREENS 60–62 — Multi-Branch Control. Aggregated performance across
/// geographic operations with cross-branch comparison.
class MultiBranchScreen extends ConsumerWidget {
  const MultiBranchScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final branches = ref.watch(branchesProvider);
    final totalRev = branches.fold(0.0, (s, b) => s + b.revenue);
    final totalOrders = branches.fold(0, (s, b) => s + b.orders);
    final maxRev =
        branches.map((b) => b.revenue).reduce((a, b) => a > b ? a : b);
    final best = branches.reduce((a, b) => a.growth > b.growth ? a : b);

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Multi-Branch Control',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Compare performance across geographic operations.',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Network Revenue', _money(totalRev),
                  Icons.account_balance_outlined, AppColors.accent),
              _kpi(t, 'Network Orders', '$totalOrders',
                  Icons.receipt_long_outlined, AppColors.info),
              _kpi(t, 'Branches', '${branches.length}',
                  Icons.store_mall_directory_outlined, AppColors.success),
              _kpi(t, 'Top Growth', '${best.name} (+${(best.growth * 100).toStringAsFixed(1)}%)',
                  Icons.trending_up, AppColors.success),
            ]),
            const SizedBox(height: 20),
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
                    Expanded(flex: 4, child: _h(t, 'BRANCH')),
                    Expanded(flex: 4, child: _h(t, 'REVENUE')),
                    Expanded(flex: 2, child: _h(t, 'ORDERS')),
                    Expanded(flex: 2, child: _h(t, 'AVG TICKET')),
                    Expanded(flex: 2, child: _h(t, 'GROWTH')),
                    SizedBox(width: 80, child: _h(t, 'STATUS')),
                  ]),
                ),
                for (int i = 0; i < branches.length; i++)
                  _row(t, branches[i], maxRev, i == branches.length - 1),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint) {
    return Container(
      width: 260,
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
                    fontSize: 17,
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

  Widget _row(AppTones t, Branch b, double maxRev, bool last) {
    final up = b.growth >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.name,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(b.city,
                  style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_money(b.revenue),
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxRev == 0 ? 0 : b.revenue / maxRev,
                  minHeight: 5,
                  backgroundColor: t.surfaceAlt,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text('${b.orders}',
              style: TextStyle(color: t.textSecondary, fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text('PKR ${b.avgTicket.toStringAsFixed(0)}',
              style: TextStyle(color: t.textSecondary, fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 13,
                color: up ? AppColors.success : AppColors.error),
            const SizedBox(width: 3),
            Text('${(b.growth * 100).abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    color: up ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ]),
        ),
        SizedBox(
          width: 80,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: (b.open ? AppColors.success : t.textMuted)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(b.open ? 'Open' : 'Closed',
                  style: TextStyle(
                      color: b.open ? AppColors.success : t.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5)),
            ),
          ),
        ),
      ]),
    );
  }
}
