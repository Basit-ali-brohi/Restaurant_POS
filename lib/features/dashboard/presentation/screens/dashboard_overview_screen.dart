import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/presentation/providers/stock_provider.dart';
import '../../../inventory/domain/models/stock_models.dart';
import '../../../table_management/domain/models/table_model.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../../../pos/domain/models/pos_models.dart';
import '../../../pos/presentation/providers/pos_providers.dart';

/// Active dashboard reporting window.
final dashboardRangeProvider = StateProvider<String>((ref) => 'Today');

/// SCREEN 6 — Main Dashboard. An enterprise command center: top analytic metric
/// containers, an inline canvas-drawn revenue line graph, and quick actions.
class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({super.key});

  static String _money(double v, {String prefix = ''}) {
    final whole = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '$prefix$buf';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final orders = ref.watch(orderRepositoryProvider);
    final tables = ref.watch(tableProvider);
    final lowStock =
        ref.watch(inventoryProvider).where((i) => i.quantity <= 0).length;

    final todaySales =
        orders.fold(0.0, (sum, o) => sum + o.breakdown.grandTotal);
    final activeTables = tables
        .where((tb) =>
            tb.status == TableStatus.occupied ||
            tb.status == TableStatus.billing)
        .length;
    final activeDeliveries =
        orders.where((o) => o.orderType == OrderType.delivery).length;

    final metrics = <_Metric>[
      _Metric('Today’s Sales', _money(todaySales, prefix: 'PKR '),
          Icons.payments_outlined, AppColors.accent),
      _Metric('Today’s Orders', '${orders.length}',
          Icons.receipt_long_outlined, AppColors.info),
      _Metric('Active Tables', '$activeTables / ${tables.length}',
          Icons.table_restaurant_outlined, AppColors.success),
      _Metric('Active Deliveries', '$activeDeliveries',
          Icons.delivery_dining_outlined, AppColors.warning),
      _Metric('Inventory Alerts', '$lowStock',
          Icons.warning_amber_rounded,
          lowStock == 0 ? AppColors.success : AppColors.error),
    ];

    // Weekly revenue series — last point reflects today's live sales.
    final revenue = <double>[4200, 5100, 4800, 6300, 5900, 7200, todaySales];

    // Order-type mix.
    final mix = <OrderType, int>{
      for (final ty in OrderType.values)
        ty: orders.where((o) => o.orderType == ty).length
    };
    // Top selling items across all orders.
    final itemQty = <String, int>{};
    for (final o in orders) {
      for (final l in o.lines) {
        itemQty[l.name] = (itemQty[l.name] ?? 0) + l.quantity;
      }
    }
    final topItems = itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Low / out of stock items.
    final lowItems = ref
        .watch(stockItemsProvider)
        .where((s) => s.isLow || s.isOut)
        .toList();

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rangeHeader(t, ref),
            const SizedBox(height: 18),
            // Metric containers.
            LayoutBuilder(builder: (context, c) {
              final perRow = c.maxWidth > 1180
                  ? 5
                  : c.maxWidth > 900
                      ? 3
                      : c.maxWidth > 560
                          ? 2
                          : 1;
              final w = (c.maxWidth - (perRow - 1) * 16) / perRow;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final m in metrics)
                    SizedBox(width: w, child: _MetricCard(tones: t, metric: m)),
                ],
              );
            }),
            const SizedBox(height: 24),
            _QuickActionCards(tones: t, ref: ref),
            const SizedBox(height: 24),
            // Revenue graph + quick actions.
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final chart = _RevenuePanel(tones: t, values: revenue, money: _money);
              final actions = _QuickActions(tones: t, ref: ref);
              if (stacked) {
                return Column(
                  children: [
                    SizedBox(height: 320, child: chart),
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }
              return SizedBox(
                height: 340,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: chart),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: actions),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // Analytics row — order mix, top items, low-stock alerts.
            LayoutBuilder(builder: (context, c) {
              final mixCard = _OrderMixCard(tones: t, mix: mix, total: orders.length);
              final topCard = _TopItemsCard(
                  tones: t, items: topItems.take(5).toList());
              final lowCard = _LowStockCard(tones: t, items: lowItems);
              if (c.maxWidth < 900) {
                return Column(children: [
                  SizedBox(height: 240, child: mixCard),
                  const SizedBox(height: 16),
                  SizedBox(height: 280, child: topCard),
                  const SizedBox(height: 16),
                  SizedBox(height: 280, child: lowCard),
                ]);
              }
              return SizedBox(
                height: 300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: mixCard),
                    const SizedBox(width: 16),
                    Expanded(child: topCard),
                    const SizedBox(width: 16),
                    Expanded(child: lowCard),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            _RecentOrders(tones: t, orders: orders, money: _money),
          ],
        ),
      ),
    );
  }

  // --- Date-range header ------------------------------------------------------
  Widget _rangeHeader(AppTones t, WidgetRef ref) {
    final range = ref.watch(dashboardRangeProvider);
    Widget chip(String label) {
      final sel = range == label;
      return GestureDetector(
        onTap: () => ref.read(dashboardRangeProvider.notifier).state = label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  color: sel ? Colors.white : t.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ),
      );
    }

    return Row(
      children: [
        Text("Today's Snapshot",
            style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Row(children: [
            chip('Today'),
            chip('7 Days'),
            chip('30 Days'),
          ]),
        ),
      ],
    );
  }
}

// =============================================================================
// QUICK ACTION CARDS
// =============================================================================

class _QuickActionCards extends StatelessWidget {
  const _QuickActionCards({required this.tones, required this.ref});
  final AppTones tones;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final actions = <_Qa>[
      _Qa('New Order', 'Start a checkout', Icons.add_shopping_cart,
          AppColors.accent, PosModule.pos),
      _Qa('Open Floor', 'Seat & manage tables', Icons.table_restaurant_outlined,
          AppColors.success, PosModule.floor),
      _Qa('Add Stock', 'Receive inventory', Icons.inventory_2_outlined,
          AppColors.info, PosModule.inventory),
      _Qa('Reservation', 'Book a table', Icons.event_seat_outlined,
          const Color(0xFF8B5CF6), PosModule.reservations),
      _Qa('Kitchen', 'Live KDS rail', Icons.soup_kitchen_outlined,
          AppColors.warning, PosModule.kitchen),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS',
            style: TextStyle(
                color: tones.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 1100
              ? 5
              : c.maxWidth > 820
                  ? 4
                  : c.maxWidth > 540
                      ? 2
                      : 1;
          final w = (c.maxWidth - (cols - 1) * 14) / cols;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [for (final a in actions) SizedBox(width: w, child: _card(a))],
          );
        }),
      ],
    );
  }

  Widget _card(_Qa a) {
    return Material(
      color: tones.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => selectModule(ref, a.module),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tones.border),
            boxShadow: [
              BoxShadow(
                  color: tones.shadow, blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(a.icon, color: a.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward, size: 16, color: tones.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.title,
                  style: TextStyle(
                      color: tones.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(a.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tones.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Qa {
  const _Qa(this.title, this.subtitle, this.icon, this.color, this.module);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final PosModule module;
}

// =============================================================================
// ANALYTICS CARDS (order mix / top items / low stock)
// =============================================================================

class _PanelBox extends StatelessWidget {
  const _PanelBox({required this.tones, required this.title, required this.child});
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
        boxShadow: [
          BoxShadow(
              color: tones.shadow, blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(title,
                style: TextStyle(
                    color: tones.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Divider(height: 1, color: tones.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _OrderMixCard extends StatelessWidget {
  const _OrderMixCard(
      {required this.tones, required this.mix, required this.total});
  final AppTones tones;
  final Map<OrderType, int> mix;
  final int total;

  static const List<Color> _palette = [
    AppColors.accent, // Dine-In
    Color(0xFFF59E0B), // Takeaway
    AppColors.success, // Delivery
  ];

  @override
  Widget build(BuildContext context) {
    final types = OrderType.values;
    return _PanelBox(
      tones: tones,
      title: 'Order Mix',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Donut chart.
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: total == 0 ? 0 : 2,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      sections: total == 0
                          ? [
                              PieChartSectionData(
                                  value: 1,
                                  color: tones.surfaceAlt,
                                  radius: 18,
                                  showTitle: false),
                            ]
                          : [
                              for (int i = 0; i < types.length; i++)
                                PieChartSectionData(
                                  value: (mix[types[i]] ?? 0).toDouble(),
                                  color: _palette[i % _palette.length],
                                  radius: 18,
                                  showTitle: false,
                                ),
                            ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total',
                          style: TextStyle(
                              color: tones.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      Text('orders',
                          style:
                              TextStyle(color: tones.textMuted, fontSize: 10.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            // Legend.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < types.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: _palette[i % _palette.length],
                              borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 8),
                        Icon(types[i].icon, size: 14, color: tones.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(types[i].label,
                              style: TextStyle(
                                  color: tones.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5)),
                        ),
                        Text('${mix[types[i]] ?? 0}',
                            style: TextStyle(
                                color: tones.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                            total == 0
                                ? '0%'
                                : '${((mix[types[i]] ?? 0) / total * 100).round()}%',
                            style: TextStyle(
                                color: tones.textMuted, fontSize: 11)),
                      ]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard({required this.tones, required this.items});
  final AppTones tones;
  final List<MapEntry<String, int>> items;

  @override
  Widget build(BuildContext context) {
    return _PanelBox(
      tones: tones,
      title: 'Top Selling Items',
      child: items.isEmpty
          ? Center(
              child: Text('No sales yet',
                  style: TextStyle(color: tones.textMuted, fontSize: 13)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final e = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  child: Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: i == 0
                              ? AppColors.accent
                              : tones.surfaceAlt,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: i == 0 ? Colors.white : tones.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: tones.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    Text('${e.value} sold',
                        style: TextStyle(
                            color: tones.textMuted, fontSize: 12)),
                  ]),
                );
              },
            ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.tones, required this.items});
  final AppTones tones;
  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    return _PanelBox(
      tones: tones,
      title: 'Low Stock Alerts',
      child: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 30),
                  const SizedBox(height: 8),
                  Text('Everything stocked',
                      style: TextStyle(color: tones.textMuted, fontSize: 12.5)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final s = items[i];
                final color =
                    s.isOut ? AppColors.error : AppColors.warning;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  child: Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: tones.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    Text(s.quantityLabel,
                        style: TextStyle(color: tones.textMuted, fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(s.isOut ? 'Out' : 'Low',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

// =============================================================================
// METRIC CONTAINER
// =============================================================================

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.tint);
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.tones, required this.metric});
  final AppTones tones;
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
        boxShadow: [
          BoxShadow(
              color: tones.shadow, blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, size: 21, color: metric.tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(metric.value,
                      style: TextStyle(
                          color: tones.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ),
                const SizedBox(height: 2),
                Text(metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tones.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REVENUE PANEL (canvas line graph)
// =============================================================================

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel(
      {required this.tones, required this.values, required this.money});
  final AppTones tones;
  final List<double> values;
  final String Function(double, {String prefix}) money;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final total = values.fold(0.0, (s, v) => s + v);
    return Container(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
        boxShadow: [
          BoxShadow(
              color: tones.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue',
                  style: TextStyle(
                      color: tones.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(money(total, prefix: 'PKR '),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text('this week',
                  style: TextStyle(color: tones.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _RevenueChartPainter(
                values: values,
                line: AppColors.accent,
                grid: tones.gridLine,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in _days)
                Text(d,
                    style: TextStyle(color: tones.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter(
      {required this.values, required this.line, required this.grid});
  final List<double> values;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b) * 1.15 + 1;

    // Horizontal grid lines.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointAt(int i) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxV) * size.height;
      return Offset(x, y);
    }

    final path = Path();
    final fill = Path();
    for (int i = 0; i < values.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, size.height);
        fill.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    // Data points; last point emphasised.
    for (int i = 0; i < values.length; i++) {
      final p = pointAt(i);
      final isLast = i == values.length - 1;
      canvas.drawCircle(p, isLast ? 5 : 3,
          Paint()..color = isLast ? line : line.withValues(alpha: 0.6));
      if (isLast) {
        canvas.drawCircle(
            p, 8, Paint()..color = line.withValues(alpha: 0.20));
      }
    }
  }

  @override
  bool shouldRepaint(_RevenueChartPainter old) => old.values != values;
}

// =============================================================================
// QUICK ACTIONS
// =============================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.tones, required this.ref});
  final AppTones tones;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
        boxShadow: [
          BoxShadow(
              color: tones.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick Actions',
              style: TextStyle(
                  color: tones.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _actionButton(
            label: 'New Order',
            icon: Icons.add_shopping_cart,
            filled: true,
            onTap: () => selectModule(ref, PosModule.pos),
          ),
          const SizedBox(height: 12),
          _actionButton(
            label: 'Purchase Order',
            icon: Icons.local_shipping_outlined,
            filled: false,
            onTap: () => selectModule(ref, PosModule.suppliers),
          ),
          const SizedBox(height: 12),
          _actionButton(
            label: 'Open Floor',
            icon: Icons.table_restaurant_outlined,
            filled: false,
            onTap: () => selectModule(ref, PosModule.floor),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tones.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tones.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tip: bind a table before billing dine-in orders',
                      style:
                          TextStyle(color: tones.textMuted, fontSize: 11.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18, color: tones.textSecondary),
              label: Text(label,
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
    );
  }
}

// =============================================================================
// RECENT ORDERS
// =============================================================================

class _RecentOrders extends StatelessWidget {
  const _RecentOrders(
      {required this.tones, required this.orders, required this.money});
  final AppTones tones;
  final List<OrderRecord> orders;
  final String Function(double, {String prefix}) money;

  @override
  Widget build(BuildContext context) {
    final recent = orders.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
        boxShadow: [
          BoxShadow(
              color: tones.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text('Recent Orders',
                style: TextStyle(
                    color: tones.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          Divider(height: 1, color: tones.border),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text('No orders yet — generate a bill in POS',
                    style: TextStyle(color: tones.textMuted, fontSize: 13)),
              ),
            )
          else
            for (final o in recent) _orderRow(o),
        ],
      ),
    );
  }

  Widget _orderRow(OrderRecord o) {
    final label = o.orderType == OrderType.dineIn && o.tableName != null
        ? 'Table ${o.tableName}'
        : o.orderType.label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tones.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(o.orderType.icon, size: 18, color: tones.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${o.billNumber}  ·  $label',
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
                Text('${o.breakdown.itemCount} item(s)',
                    style: TextStyle(color: tones.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(money(o.breakdown.grandTotal, prefix: 'PKR '),
              style: TextStyle(
                  color: tones.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
