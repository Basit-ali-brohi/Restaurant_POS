import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/inventory_provider.dart';
import '../../domain/models/inventory_item_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _selectedFilter = 'All Items';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final externalFilter = ref.watch(inventorySelectedFilterProvider);
    if (_selectedFilter != externalFilter) {
      _selectedFilter = externalFilter;
    }
    final suppliers = ref.watch(suppliersProvider);
    final restockRequests = ref.watch(restockRequestsProvider);
    final pendingCount = restockRequests.where((r) => r.status != 'received').length;
    final allItems = ref.watch(inventoryProvider);

    // Filter Logic
    List<InventoryItemModel> filteredItems = allItems;
    if (_selectedFilter == 'Low Stock') {
      filteredItems = filteredItems.where((i) => i.status == 'Low').toList();
    }
    
    // Search Logic
    if (_searchController.text.isNotEmpty) {
      filteredItems = filteredItems.where((i) => i.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;
          
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Management',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              
              // Dashboard Stats
              if (isSmallScreen)
                Column(
                  children: [
                    _StatCard(
                      title: "Total Value",
                      value: "PKR 12,450",
                      icon: Icons.monetization_on,
                      color: Colors.greenAccent,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: "Low Stock Items",
                      value: "${allItems.where((i) => i.status == 'Low').length}",
                      icon: Icons.warning_amber,
                      color: Colors.orangeAccent,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: "Total Items",
                      value: allItems.length.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blueAccent,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _StatCard(title: "Total Value", value: "PKR 12,450", icon: Icons.monetization_on, color: Colors.greenAccent, isDarkMode: isDarkMode)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(title: "Low Stock Items", value: "${allItems.where((i) => i.status == 'Low').length}", icon: Icons.warning_amber, color: Colors.orangeAccent, isDarkMode: isDarkMode)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: "Total Items",
                        value: allItems.length.toString(),
                        icon: Icons.inventory_2,
                        color: Colors.blueAccent,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),

              // Filters & Search
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterTab(
                      label: "All Items",
                      isSelected: _selectedFilter == "All Items",
                      isDarkMode: isDarkMode,
                      onTap: () {
                        ref.read(inventorySelectedFilterProvider.notifier).state = "All Items";
                        setState(() => _selectedFilter = "All Items");
                      },
                    ),
                    const SizedBox(width: 12),
                    _FilterTab(
                      label: "Low Stock",
                      isSelected: _selectedFilter == "Low Stock",
                      isDarkMode: isDarkMode,
                      onTap: () {
                        ref.read(inventorySelectedFilterProvider.notifier).state = "Low Stock";
                        setState(() => _selectedFilter = "Low Stock");
                      },
                    ),
                    const SizedBox(width: 12),
                    _FilterTab(
                      label: "Ingredients",
                      isSelected: _selectedFilter == "Ingredients",
                      isDarkMode: isDarkMode,
                      onTap: () {
                        ref.read(inventorySelectedFilterProvider.notifier).state = "Ingredients";
                        setState(() => _selectedFilter = "Ingredients");
                      },
                    ),
                    const SizedBox(width: 12),
                    // Search Box
                    Container(
                      width: isSmallScreen ? 200 : 250,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() {}),
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Search...",
                                hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionButton(
                      icon: Icons.people_alt_outlined,
                      label: isSmallScreen ? "" : "Suppliers",
                      isDarkMode: isDarkMode,
                      onTap: () => _showSuppliersSheet(context, isDarkMode),
                    ),
                    const SizedBox(width: 10),
                    _QuickActionButton(
                      icon: Icons.receipt_long,
                      label: isSmallScreen ? "" : "Requests",
                      isDarkMode: isDarkMode,
                      onTap: () => _showRequestsSheet(context, isDarkMode),
                      badgeCount: pendingCount,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              isSmallScreen 
                ? _buildInventoryList(context, ref, filteredItems, isDarkMode, isSmallScreen)
                : Expanded(
                    child: _buildInventoryList(context, ref, filteredItems, isDarkMode, isSmallScreen)
                  ),
            ],
          );
          
          return Stack(
            children: [
              if (isDarkMode) Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isSmallScreen ? SingleChildScrollView(child: content) : content,
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItemModel> filteredItems,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    Widget listContent = ListView.separated(
      padding: isSmallScreen ? const EdgeInsets.all(16) : EdgeInsets.zero,
      itemCount: filteredItems.length,
      shrinkWrap: isSmallScreen,
      physics: isSmallScreen ? const NeverScrollableScrollPhysics() : null,
      separatorBuilder: (_, __) => isSmallScreen
          ? const SizedBox(height: 16)
          : Divider(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              height: 1),
      itemBuilder: (context, index) {
        final item = filteredItems[index];

        if (isSmallScreen) {
          // Card View for Small Screens
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDarkMode ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _statusBadge(item.status, isDarkMode),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Stock Level:",
                        style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 15)),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.level,
                          backgroundColor:
                              isDarkMode ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.level < 0.3
                                ? Colors.redAccent
                                : (item.level < 0.6
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Quantity:",
                        style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 15)),
                    Flexible(
                      child: Text(
                        item.quantityLabel,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.status.toLowerCase() == 'low') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showRestockForm(context, ref, item, isDarkMode),
                      icon: const Icon(Icons.add_shopping_cart, size: 14),
                      label: const Text("Restock"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Table Row for Large Screens
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(item.name,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.level,
                      backgroundColor:
                          isDarkMode ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.level < 0.3
                            ? Colors.redAccent
                            : (item.level < 0.6
                                ? Colors.orangeAccent
                                : Colors.greenAccent),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Text(item.quantityLabel,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54))),
              Expanded(
                  flex: 2,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: _statusBadge(item.status, isDarkMode))),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: (item.status.toLowerCase() == 'low')
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              _showRestockForm(context, ref, item, isDarkMode),
                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                          label: const Text("Restock"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        );
      },
    );

    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      child: GlassContainer(
        borderRadius: 16,
        color: isDarkMode
            ? AppColors.surface.withOpacity(0.45)
            : Colors.white.withOpacity(0.45),
        padding: const EdgeInsets.all(0),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Crucial for shrinkWrap
          children: [
            // Table Header - Hide on small screens if using cards
            if (!isSmallScreen)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text("Item Name",
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text("Stock Level",
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text("Quantity",
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text("Status",
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text("Action",
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            // List Items
            isSmallScreen ? listContent : Expanded(child: listContent),
          ],
        ),
      ),
    );
  }

  static Widget _statusBadge(String status, bool isDarkMode) {
    final isLow = status.toLowerCase() == 'low';
    final color = isLow ? Colors.redAccent : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Future<void> _showRestockForm(BuildContext context, WidgetRef ref, InventoryItemModel item, bool isDarkMode) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final qtyController = TextEditingController(text: "1 ${item.unit}");
        final suppliers = ref.read(suppliersProvider);
        String? selectedSupplierId = suppliers.isNotEmpty ? suppliers.first.id : null;
        return SlideInUp(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                return GlassContainer(
                  borderRadius: 16,
                  color: isDarkMode ? AppColors.surface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.all(16),
                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text("Restock ${item.name}", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Quantity",
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSupplierId,
                        items: suppliers
                            .map((s) => DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(s.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                                ))
                            .toList(),
                        onChanged: suppliers.isEmpty
                            ? null
                            : (v) {
                                setModalState(() => selectedSupplierId = v);
                              },
                        decoration: InputDecoration(
                          labelText: "Supplier",
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final qtyLabel = qtyController.text.trim();
                            Navigator.of(ctx).pop();
                            ref.read(restockRequestsProvider.notifier).createRequest(itemName: item.name, quantityLabel: qtyLabel, supplierId: selectedSupplierId);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Restock request sent for ${item.name}")));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Send to Supplier"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSuppliersSheet(BuildContext context, bool isDarkMode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(builder: (context, ref, _) {
          final suppliers = ref.watch(suppliersProvider);
          return SlideInUp(
            duration: const Duration(milliseconds: 350),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                borderRadius: 16,
                color: isDarkMode ? AppColors.surface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.all(16),
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text("Suppliers", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.close, color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 360,
                      child: suppliers.isEmpty
                          ? Center(child: Text("No suppliers", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)))
                          : ListView.separated(
                              itemCount: suppliers.length,
                              separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                              itemBuilder: (context, index) {
                                final s = suppliers[index];
                                return Row(
                                  children: [
                                    Expanded(child: Text(s.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 12),
                                    Text(s.contact, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _showRequestsSheet(BuildContext context, bool isDarkMode) async {
    String two(int n) => n.toString().padLeft(2, '0');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(builder: (context, ref, _) {
          final suppliers = ref.watch(suppliersProvider);
          final requests = [...ref.watch(restockRequestsProvider)]..sort((a, b) => b.time.compareTo(a.time));
          String supplierName(String? id) {
            if (id == null) return "-";
            final found = suppliers.where((s) => s.id == id).toList();
            return found.isEmpty ? id : found.first.name;
          }

          return SlideInUp(
            duration: const Duration(milliseconds: 350),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                borderRadius: 16,
                color: isDarkMode ? AppColors.surface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.all(16),
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text("Restock Requests", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.close, color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 420,
                      child: requests.isEmpty
                          ? Center(child: Text("No requests yet", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)))
                          : ListView.separated(
                              itemCount: requests.length,
                              separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                              itemBuilder: (context, index) {
                                final r = requests[index];
                                final t = r.time;
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(r.itemName, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(r.quantityLabel, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(supplierName(r.supplierId), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text("${two(t.hour)}:${two(t.minute)}", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black45)),
                                    ),
                                    const SizedBox(width: 12),
                                    r.status == 'received'
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent.withOpacity(isDarkMode ? 0.18 : 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                                            ),
                                            child: Text("Received", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                                          )
                                        : ElevatedButton(
                                            onPressed: () async {
                                              await ref.read(restockRequestsProvider.notifier).acceptRequest(r.id);
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request received: ${r.itemName}")));
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            child: const Text("Accept"),
                                          ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

// removed local _InvItem; using InventoryItemModel via provider

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      color: isDarkMode ? color.withOpacity(0.1) : Colors.white.withOpacity(0.6),
      border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 24)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;
  final int? badgeCount;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accent : (isDarkMode ? Colors.white24 : Colors.black26)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
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
