import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../dashboard/presentation/providers/sales_provider.dart';

enum TimeFilter { today, weekly }

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  TimeFilter _filter = TimeFilter.today;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final sales = ref.watch(salesProvider);
    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final filtered = _filter == TimeFilter.today
        ? sales.where((t) => isSameDay(t.time, now)).toList()
        : sales.where((t) => t.time.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final paid = filtered.where((t) => t.status == TransactionStatus.paid).toList();
    final totalRevenue = paid.fold<double>(0, (sum, t) => sum + t.total);
    final totalOrders = filtered.length;
    final avgPrep = _filter == TimeFilter.today ? "14 mins" : "16 mins";
    final todayHourly = List<double>.filled(24, 0);
    for (final t in paid.where((tx) => isSameDay(tx.time, now))) {
      todayHourly[t.time.hour] += t.total;
    }
    final weeklyDaily = List<double>.filled(7, 0);
    for (final t in paid.where((tx) => tx.time.isAfter(now.subtract(const Duration(days: 7))))) {
      final idx = now.difference(DateTime(t.time.year, t.time.month, t.time.day)).inDays;
      final pos = idx >= 0 && idx < 7 ? (6 - idx) : null;
      if (pos != null) weeklyDaily[pos] += t.total;
    }
    final topSellers = const [
      _TopSeller("Truffle Fries", "https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=120&q=40", 52),
      _TopSeller("Signature Steak", "https://images.unsplash.com/photo-1600891964092-4316c288032e?auto=format&fit=crop&w=120&q=40", 41),
      _TopSeller("Mojito", "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?auto=format&fit=crop&w=120&q=40", 39),
      _TopSeller("Lobster Risotto", "https://images.unsplash.com/photo-1595295333158-4742f28fbd85?auto=format&fit=crop&w=120&q=40", 33),
      _TopSeller("Molten Lava Cake", "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=120&q=40", 29),
    ];
    final cashTotal = paid.fold<double>(0, (sum, t) => sum + t.cashAmount);
    final cardTotal = paid.fold<double>(0, (sum, t) => sum + t.cardAmount);
    final otherTotal = ((totalRevenue - cashTotal - cardTotal).clamp(0, double.infinity)).toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          
          if (isMobile) {
             return Stack(
              children: [
                if (isDarkMode) Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(isDarkMode),
                      const SizedBox(height: 16),
                      // Scrollable Stats
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 260,
                              child: _statCard("Total Revenue", "\$${totalRevenue.toStringAsFixed(2)}", Icons.trending_up, Colors.greenAccent, 0, true, isDarkMode),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 260,
                              child: _statCard("Total Orders", "$totalOrders Orders", Icons.receipt_long, AppColors.accent, 0, true, isDarkMode),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 260,
                              child: _statCard("Avg. Prep Time", avgPrep, Icons.access_time, Colors.orangeAccent, 0, false, isDarkMode),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Fixed height charts for mobile
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 300,
                          child: _buildLiveChart(isDarkMode, todayHourly, weeklyDaily),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 250,
                          child: _buildPaymentMix(isDarkMode, cashTotal, cardTotal, otherTotal),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 300,
                          child: _buildTopSellers(isDarkMode, topSellers),
                        ),
                      ),
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ],
            );
          }

          // Desktop / Tablet Layout
          return Stack(
            children: [
              if (isDarkMode) Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
              Column(
                children: [
                  _buildHeader(isDarkMode),
                  // Top Row: Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SlideInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Expanded(child: _statCard(
                            "Total Revenue",
                            "\$${totalRevenue.toStringAsFixed(2)}",
                            Icons.trending_up,
                            Colors.greenAccent,
                            0,
                            true,
                            isDarkMode,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _statCard(
                            "Total Orders",
                            "$totalOrders Orders",
                            Icons.receipt_long,
                            AppColors.accent,
                            0,
                            true,
                            isDarkMode,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _statCard(
                            "Avg. Prep Time",
                            avgPrep,
                            Icons.access_time,
                            Colors.orangeAccent,
                            0,
                            false,
                            isDarkMode,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Middle: Live Sales Chart
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildLiveChart(isDarkMode, todayHourly, weeklyDaily),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment Mix
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildPaymentMix(isDarkMode, cashTotal, cardTotal, otherTotal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom: Top Sellers
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildTopSellers(isDarkMode, topSellers),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Insights",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surface.withOpacity(0.4) : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
            ),
            child: DropdownButton<TimeFilter>(
              value: _filter,
              dropdownColor: isDarkMode ? const Color(0xFF0B0E13) : Colors.white,
              underline: const SizedBox(),
              iconEnabledColor: isDarkMode ? Colors.white70 : Colors.black54,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              items: [
                DropdownMenuItem(value: TimeFilter.today, child: Text("Today", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87))),
                DropdownMenuItem(value: TimeFilter.weekly, child: Text("Weekly", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87))),
              ],
              onChanged: (v) => setState(() => _filter = v ?? TimeFilter.today),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChart(bool isDarkMode, List<double> todayHourly, List<double> weeklyDaily) {
    final currentData = _filter == TimeFilter.today ? todayHourly : weeklyDaily;
    final maxVal = currentData.reduce(math.max);
    final targetMaxY = maxVal > 0 ? maxVal * 1.2 : 10.0;
    final horizontalInterval = targetMaxY / 5;

    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      child: GlassContainer(
        borderRadius: 16,
        color: isDarkMode ? AppColors.surface.withOpacity(0.45) : Colors.white.withOpacity(0.45),
        padding: const EdgeInsets.all(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: _filter == TimeFilter.today ? 23 : 6,
            minY: 0,
            maxY: targetMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              verticalInterval: _filter == TimeFilter.today ? 4 : 1,
              horizontalInterval: horizontalInterval,
              getDrawingHorizontalLine: (value) => FlLine(color: isDarkMode ? Colors.white10 : Colors.black12, strokeWidth: 1),
              getDrawingVerticalLine: (value) => FlLine(color: isDarkMode ? Colors.white10 : Colors.black12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      v.toStringAsFixed(0),
                      style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _filter == TimeFilter.today ? 4 : 1,
                  getTitlesWidget: (v, meta) {
                    final label = _filter == TimeFilter.today
                        ? "${v.toInt()}h"
                        : ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][v.toInt().clamp(0, 6)];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items.map((it) {
                  final label = _filter == TimeFilter.today ? "${it.x.toInt()}h" : "Day ${it.x.toInt()+1}";
                  return LineTooltipItem("$label\n${it.y.toStringAsFixed(0)}", TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold));
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: AppColors.accent,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                spots: _filter == TimeFilter.today
                    ? List.generate(24, (h) => FlSpot(h.toDouble(), todayHourly[h]))
                    : List.generate(7, (d) => FlSpot(d.toDouble(), weeklyDaily[d])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMix(bool isDarkMode, double cashTotal, double cardTotal, double otherTotal) {
    return SlideInUp(
      duration: const Duration(milliseconds: 550),
      child: GlassContainer(
        borderRadius: 16,
        color: isDarkMode ? AppColors.surface.withOpacity(0.45) : Colors.white.withOpacity(0.45),
        padding: const EdgeInsets.all(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final radius = h < 160 ? h * 0.35 : 60.0;
            final centerRadius = radius * 0.8;
            final total = cashTotal + cardTotal + otherTotal;
            return Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: centerRadius,
                          sections: [
                            PieChartSectionData(
                              color: AppColors.success,
                              value: cashTotal,
                              title: "",
                              radius: radius,
                              titleStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            PieChartSectionData(
                              color: AppColors.accent,
                              value: cardTotal,
                              title: "",
                              radius: radius,
                              titleStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            PieChartSectionData(
                              color: Colors.blueGrey,
                              value: otherTotal,
                              title: "",
                              radius: radius,
                              titleStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("100%", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 2),
                            Text("\$${total.toStringAsFixed(2)}", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text("Payments", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend(isDarkMode, color: AppColors.success, label: "Cash", value: cashTotal),
                        const SizedBox(height: 8),
                        _legend(isDarkMode, color: AppColors.accent, label: "Card", value: cardTotal),
                        const SizedBox(height: 8),
                        _legend(isDarkMode, color: Colors.blueGrey, label: "Other", value: otherTotal),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSellers(bool isDarkMode, List<_TopSeller> topSellers) {
    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      child: GlassContainer(
        borderRadius: 16,
        color: isDarkMode ? AppColors.surface.withOpacity(0.45) : Colors.white.withOpacity(0.45),
        padding: const EdgeInsets.all(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top 5 Best Sellers",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalH = constraints.maxHeight;
                  if (totalH <= 0 || !totalH.isFinite) return const SizedBox.shrink();

                  const gap = 8.0;
                  const minBarH = 80.0;
                  const minThumbsH = 56.0;

                  if (totalH <= minBarH + gap + minThumbsH) {
                    return BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(v.toInt().toString(), style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11)),
                            );
                          })),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            final label = i >= 0 && i < topSellers.length ? topSellers[i].name.split(' ').first : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11)),
                            );
                          })),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(topSellers.length, (i) => _barGroup(i, topSellers[i].count.toDouble())),
                      ),
                    );
                  }

                  var thumbsH = math.min(110.0, math.max(minThumbsH, totalH * 0.32));
                  var barH = totalH - thumbsH - gap;
                  if (barH < minBarH) {
                    thumbsH = math.max(minThumbsH, totalH - minBarH - gap);
                    barH = totalH - thumbsH - gap;
                  }
                  final thumbSize = math.min(64.0, math.max(44.0, thumbsH - 26));

                  return Column(
                    children: [
                      SizedBox(
                        height: barH,
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(v.toInt().toString(), style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11)),
                                );
                              })),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                final label = i >= 0 && i < topSellers.length ? topSellers[i].name.split(' ').first : '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11)),
                                );
                              })),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(topSellers.length, (i) => _barGroup(i, topSellers[i].count.toDouble())),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: thumbsH,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemCount: topSellers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = topSellers[index];
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item.imageUrl, width: thumbSize, height: thumbSize, fit: BoxFit.cover),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: thumbSize + 8,
                                  child: Text(
                                    "${item.name} (${item.count}x)",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 11),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color accentColor, int growthPercent, bool positive, bool isDarkMode) {
    return GlassContainer(
      borderRadius: 16,
      color: isDarkMode ? AppColors.surface.withOpacity(0.45) : Colors.white.withOpacity(0.45),
      padding: const EdgeInsets.all(16),
      border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor, width: 1),
              boxShadow: [
                BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 18, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14, color: positive ? Colors.greenAccent : Colors.redAccent),
                  Text(
                    "${growthPercent.abs()}%",
                    style: TextStyle(
                      color: positive ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.accent,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _legend(bool isDarkMode, {required Color color, required String label, required double value}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
        const SizedBox(width: 8),
        Text("\$${value.toStringAsFixed(2)}", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TopSeller {
  final String name;
  final String imageUrl;
  final int count;
  const _TopSeller(this.name, this.imageUrl, this.count);
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06);
    for (int i = 0; i < 120; i++) {
      final dx = (i * 73) % size.width;
      final dy = (i * 59) % size.height;
      canvas.drawCircle(Offset(dx.toDouble(), dy.toDouble()), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
