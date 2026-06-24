import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';

class Branch {
  final String id;
  final String name;
  final String city;
  final double revenue;
  final int orders;
  final double avgTicket;
  final double growth; // fractional, +/-
  final double laborCostPct;
  final bool open;

  const Branch({
    required this.id,
    required this.name,
    required this.city,
    this.revenue = 0,
    this.orders = 0,
    this.avgTicket = 0,
    this.growth = 0,
    this.laborCostPct = 0.25,
    this.open = true,
  });
}

class BranchesNotifier extends StateNotifier<List<Branch>> {
  BranchesNotifier() : super(_seed) {
    _load();
  }

  final _db = DbService.instance;
  int _seq = 5;

  static const List<Branch> _seed = [
    Branch(id: 'B-01', name: 'Main Dining', city: 'Lahore · Gulberg', revenue: 1842300, orders: 4120, avgTicket: 447, growth: 0.124, laborCostPct: 0.245, open: true),
    Branch(id: 'B-02', name: 'Downtown Branch', city: 'Lahore · Mall Rd', revenue: 1235600, orders: 3010, avgTicket: 410, growth: 0.082, laborCostPct: 0.268, open: true),
    Branch(id: 'B-03', name: 'Airport Kiosk', city: 'Lahore · Allama Iqbal', revenue: 684900, orders: 2280, avgTicket: 300, growth: -0.031, laborCostPct: 0.221, open: true),
    Branch(id: 'B-04', name: 'Seaview Outlet', city: 'Karachi · Clifton', revenue: 1521000, orders: 3460, avgTicket: 439, growth: 0.156, laborCostPct: 0.252, open: true),
    Branch(id: 'B-05', name: 'Capital Branch', city: 'Islamabad · F-7', revenue: 998200, orders: 2540, avgTicket: 393, growth: 0.044, laborCostPct: 0.239, open: false),
  ];

  Branch _fromRow(Map<String, String?> r) => Branch(
        id: r['id'] ?? '',
        name: r['name'] ?? '',
        city: r['location'] ?? '',
        revenue: double.tryParse(r['revenue'] ?? '') ?? 0,
        orders: int.tryParse(r['orders'] ?? '') ?? 0,
        avgTicket: double.tryParse(r['avg_ticket'] ?? '') ?? 0,
        growth: double.tryParse(r['growth'] ?? '') ?? 0,
        open: (r['is_open'] ?? '1') == '1',
      );

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows = await _db.rows('SELECT * FROM branches ORDER BY id');
    if (rows.isEmpty) {
      for (final b in _seed) {
        await _persist(b);
      }
    } else {
      state = rows.map(_fromRow).toList();
      for (final b in state) {
        final n = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (n != null && n > _seq) _seq = n;
      }
    }
  }

  Future<void> _persist(Branch b) => _db.exec(
        'INSERT INTO branches (id,name,location,revenue,orders,avg_ticket,growth,is_open) '
        'VALUES (:id,:name,:loc,:rev,:ord,:avg,:gr,:open) '
        'ON DUPLICATE KEY UPDATE name=:name, location=:loc, revenue=:rev, '
        'orders=:ord, avg_ticket=:avg, growth=:gr, is_open=:open',
        {
          'id': b.id,
          'name': b.name,
          'loc': b.city,
          'rev': b.revenue,
          'ord': b.orders,
          'avg': b.avgTicket,
          'gr': b.growth,
          'open': b.open ? 1 : 0,
        },
      );

  void add({
    required String name,
    required String city,
    double revenue = 0,
    int orders = 0,
    bool open = true,
  }) {
    final b = Branch(
      id: 'B-${(++_seq).toString().padLeft(2, '0')}',
      name: name.trim(),
      city: city.trim(),
      revenue: revenue,
      orders: orders,
      avgTicket: orders > 0 ? revenue / orders : 0,
      growth: 0,
      open: open,
    );
    state = [...state, b];
    _persist(b);
  }

  void remove(String id) {
    state = state.where((b) => b.id != id).toList();
    _db.exec('DELETE FROM branches WHERE id=:id', {'id': id});
  }
}

final branchesProvider =
    StateNotifierProvider<BranchesNotifier, List<Branch>>(
        (ref) => BranchesNotifier());

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
            Row(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Multi-Branch Control',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Compare performance across geographic operations.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddBranch(context, ref),
                  icon: const Icon(Icons.add_business, size: 18),
                  label: const Text('Add Branch',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
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
                    const SizedBox(width: 36),
                  ]),
                ),
                for (int i = 0; i < branches.length; i++)
                  _row(context, ref, t, branches[i], maxRev,
                      i == branches.length - 1),
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

  Widget _row(BuildContext context, WidgetRef ref, AppTones t, Branch b,
      double maxRev, bool last) {
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
        SizedBox(
          width: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Delete branch',
            icon: Icon(Icons.delete_outline,
                size: 18, color: AppColors.error.withValues(alpha: 0.8)),
            onPressed: () {
              ref.read(branchesProvider.notifier).remove(b.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Removed ${b.name}'),
                duration: const Duration(milliseconds: 900),
                backgroundColor: AppColors.error,
              ));
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _showAddBranch(BuildContext context, WidgetRef ref) async {
    final t = AppTones(ref.read(themeProvider));
    final name = TextEditingController();
    final city = TextEditingController();
    final revenue = TextEditingController();
    final orders = TextEditingController();
    bool open = true;
    String? error;

    InputDecoration dec(String h) => InputDecoration(
          isDense: true,
          hintText: h,
          hintStyle: TextStyle(color: t.textMuted),
          filled: true,
          fillColor: t.surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        );
    Widget field(String label, TextEditingController c,
            {bool number = false}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: t.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(
            controller: c,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: TextStyle(color: t.textPrimary, fontSize: 14),
            decoration: dec(label),
          ),
        ]);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Branch',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  field('Branch name', name),
                  const SizedBox(height: 12),
                  field('City / location', city),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: field('Revenue (PKR)', revenue, number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: field('Orders', orders, number: true)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Text('Status',
                        style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Open'),
                      selected: open,
                      onSelected: (_) => setLocal(() => open = true),
                      selectedColor: AppColors.success.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Closed'),
                      selected: !open,
                      onSelected: (_) => setLocal(() => open = false),
                      selectedColor: t.surfaceAlt,
                    ),
                  ]),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 18),
                  Row(children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:
                          Text('Cancel', style: TextStyle(color: t.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (name.text.trim().isEmpty) {
                          setLocal(() => error = 'Branch name is required');
                          return;
                        }
                        ref.read(branchesProvider.notifier).add(
                              name: name.text.trim(),
                              city: city.text.trim(),
                              revenue:
                                  double.tryParse(revenue.text.trim()) ?? 0,
                              orders: int.tryParse(orders.text.trim()) ?? 0,
                              open: open,
                            );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add Branch',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
