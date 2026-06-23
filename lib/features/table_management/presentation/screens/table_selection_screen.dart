import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../domain/models/table_model.dart';
import '../providers/table_provider.dart';
import '../widgets/table_widget.dart';

class TableSelectionScreen extends ConsumerStatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  ConsumerState<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends ConsumerState<TableSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<String> _sections = ['Ground Floor', 'First Floor', 'Outdoor'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tableProvider);
    final isDarkMode = ref.watch(themeProvider);

    // Filter tables based on search query
    final filteredTables = tables.where((table) {
      return table.name.toLowerCase().contains(_searchQuery);
    }).toList();

    // Calculate Stats
    final int totalTables = tables.length;
    final int occupiedTables = tables.where((t) => t.status == TableStatus.occupied).length;
    final int freeTables = tables.where((t) => t.status == TableStatus.available).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800;
          
          return Column(
            children: [
              // 1. Quick Stats & Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isSmallScreen 
                  ? Column(
                      children: [
                        // Quick Stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem("Total", totalTables.toString(), isDarkMode ? Colors.white : Colors.black87, isDarkMode),
                              _buildStatItem("Occupied", occupiedTables.toString(), AppColors.error, isDarkMode),
                              _buildStatItem("Free", freeTables.toString(), AppColors.success, isDarkMode),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Search Bar + Low Stock Badge
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: "Search Table Number...",
                                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45),
                                    border: InputBorder.none,
                                    icon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black45),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const LowStockBadgeButton(),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Quick Stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            children: [
                              _buildStatItem("Total", totalTables.toString(), isDarkMode ? Colors.white : Colors.black87, isDarkMode),
                              const SizedBox(width: 16),
                              _buildStatItem("Occupied", occupiedTables.toString(), AppColors.error, isDarkMode),
                              const SizedBox(width: 16),
                              _buildStatItem("Free", freeTables.toString(), AppColors.success, isDarkMode),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Search Bar + Low Stock Badge
                        Row(
                          children: [
                            Container(
                              width: 300,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Search Table Number...",
                                  hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45),
                                  border: InputBorder.none,
                                  icon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black45),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const LowStockBadgeButton(),
                          ],
                        ),
                      ],
                    ),
              ),

              // 2. Floor Sections (Tabs)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.surface.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: isDarkMode ? Colors.white : Colors.black54,
                  tabs: _sections.map((section) => Tab(text: section)).toList(),
                ),
              ),
              
              const SizedBox(height: 16),

              // 3. Scrollable Grid
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _sections.map((section) {
                    // Filter by section
                    final sectionTables = filteredTables.where((t) => t.section == section).toList();
                    
                    if (sectionTables.isEmpty) {
                      return Center(
                        child: Text(
                          "No tables found",
                          style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45, fontSize: 18),
                        ),
                      );
                    }

                    int crossAxisCount = 2;
                    if (constraints.maxWidth > 600) crossAxisCount = 3;
                    if (constraints.maxWidth > 900) crossAxisCount = 4;
                    if (constraints.maxWidth > 1200) crossAxisCount = 5;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: sectionTables.length,
                      itemBuilder: (context, index) {
                        final table = sectionTables[index];
                        return TableWidget(
                          table: table,
                          onTap: () {
                            // Navigate to Menu
                            ref.read(selectedTableNameProvider.notifier).state = table.name;
                            ref.read(dashboardIndexProvider.notifier).state = 1;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Table ${table.name} Selected")),
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDarkMode) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class LowStockBadgeButton extends ConsumerWidget {
  const LowStockBadgeButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final lowCount = ref.watch(inventoryProvider).where((i) => i.status.toLowerCase() == 'low').length;
    return InkWell(
      onTap: () {
        ref.read(inventorySelectedFilterProvider.notifier).state = 'Low Stock';
        ref.read(dashboardIndexProvider.notifier).state = 4;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.warning_amber, color: Colors.orangeAccent),
            if (lowCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    lowCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
