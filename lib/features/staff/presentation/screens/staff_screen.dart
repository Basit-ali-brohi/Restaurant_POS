import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final staff = const [
      _StaffRow('Ali', 620),
      _StaffRow('Sana', 540),
      _StaffRow('Imran', 480),
      _StaffRow('Ayesha', 430),
      _StaffRow('Usman', 390),
    ];
    final topSales = staff.map((s) => s.sales).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;
          final contentWidth = isSmallScreen ? constraints.maxWidth : 800.0;
          
          return Stack(
            children: [
              if (isDarkMode) Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SlideInUp(
                          duration: const Duration(milliseconds: 600),
                          child: GlassContainer(
                            borderRadius: 16,
                            color: isDarkMode ? AppColors.surface.withOpacity(0.45) : Colors.white.withOpacity(0.45),
                            padding: const EdgeInsets.all(16),
                            child: ListView.separated(
                              itemCount: staff.length,
                              separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white12 : Colors.black12),
                              itemBuilder: (context, index) {
                                final s = staff[index];
                                return FadeInUp(
                                  duration: const Duration(milliseconds: 500),
                                  delay: Duration(milliseconds: index * 90),
                                  child: InkWell(
                                    onTap: () => _showStaffDetail(context, s, isDarkMode),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isDarkMode ? Colors.white24 : Colors.black12,
                                          child: Icon(Icons.person, color: isDarkMode ? Colors.white : Colors.black54),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                s.name,
                                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                                              ),
                                              if (s.sales == topSales) ...[
                                                const SizedBox(width: 6),
                                                const Icon(Icons.workspace_premium, color: AppColors.accent, size: 18),
                                              ]
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.accent),
                                          ),
                                          child: Text(
                                            "PKR ${s.sales}",
                                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showStaffDetail(BuildContext context, _StaffRow s, bool isDarkMode) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SlideInUp(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
            ),
            child: GlassContainer(
              borderRadius: 16,
              color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.9),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDarkMode ? Colors.white24 : Colors.black12,
                        child: Icon(Icons.person, color: isDarkMode ? Colors.white : Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Today's Sales: PKR ${s.sales}", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showDummyReport(context, s, isDarkMode);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: const Text("View Report", style: TextStyle(color: AppColors.accent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orangeAccent, size: 18),
                      const Icon(Icons.star, color: Colors.orangeAccent, size: 18),
                      const Icon(Icons.star, color: Colors.orangeAccent, size: 18),
                      const Icon(Icons.star_half, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 6),
                      Text("Rating 3.5", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [AppColors.accent.withOpacity(0.3), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            spots: const [
                              FlSpot(0, 1.2),
                              FlSpot(1, 2.0),
                              FlSpot(2, 1.6),
                              FlSpot(3, 2.8),
                              FlSpot(4, 2.4),
                              FlSpot(5, 3.1),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDummyReport(BuildContext context, _StaffRow s, bool isDarkMode) {
    return showDialog(
      context: context,
      builder: (ctx) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: GlassContainer(
                width: isSmallScreen ? constraints.maxWidth * 0.9 : 500,
                borderRadius: 16,
                padding: const EdgeInsets.all(24),
                color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Performance Report",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Staff: ${s.name}",
                                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.assessment, color: AppColors.accent, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: isDarkMode ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 16),
                      
                      // Stats Grid
                      Row(
                        children: [
                          Expanded(child: _buildReportStat("Total Orders", "42", Icons.receipt_long, isDarkMode)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildReportStat("Avg. Rating", "4.8", Icons.star, isDarkMode)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildReportStat("Sales Volume", "PKR ${s.sales}", Icons.attach_money, isDarkMode)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildReportStat("Shift Hours", "8h 30m", Icons.access_time, isDarkMode)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      Text(
                        "Recent Activity",
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            _buildActivityRow("Table 5 Order", "10:23 AM", "PKR 45.00", isDarkMode),
                            _buildActivityRow("Table 2 Payment", "10:15 AM", "PKR 120.50", isDarkMode),
                            _buildActivityRow("Shift Started", "09:00 AM", "-", isDarkMode),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Report exported to PDF")),
                              );
                            },
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("Export"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportStat(String label, String value, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 11), overflow: TextOverflow.ellipsis),
                Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String action, String time, String amount, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
          Row(
            children: [
              Text(time, style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38, fontSize: 12)),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  amount, 
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffRow {
  final String name;
  final int sales;
  const _StaffRow(this.name, this.sales);
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
