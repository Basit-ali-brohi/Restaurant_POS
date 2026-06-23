import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/cart_provider.dart';
import '../../domain/models/cart_item_model.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../../../kitchen/domain/models/order_model.dart';
import '../../../kitchen/presentation/providers/kitchen_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/providers/shift_provider.dart';
import '../../../dashboard/presentation/providers/sales_provider.dart';
import 'feedback_dialog.dart';
import 'package:uuid/uuid.dart';

enum CheckoutIntent { settle, split, discount }

class CartSidebar extends ConsumerWidget {
  const CartSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final isDarkMode = ref.watch(themeProvider);

    return ClipRRect( // Added ClipRRect for blur effect containment
      child: BackdropFilter( // Added BackdropFilter for blur
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
             color: isDarkMode ? AppColors.surface.withOpacity(0.2) : Colors.white.withOpacity(0.6),
             border: Border(
               left: BorderSide(
                 color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                 width: 1,
               ),
             ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInRight(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "Current Order",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: cartItems.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 48, color: isDarkMode ? Colors.white24 : Colors.black26),
                          SizedBox(height: 16),
                          Text("Cart is empty", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildCartItem(context, ref, item, isDarkMode),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 12),
              Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.call_split,
                    label: "Split",
                    onTap: () async {
                      final selectedTable = ref.read(selectedTableNameProvider);
                      await _openCheckoutDialog(
                        context: context,
                        ref: ref,
                        items: cartItems,
                        subtotal: total,
                        tableName: selectedTable,
                        isDarkMode: isDarkMode,
                        intent: CheckoutIntent.split,
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),
                  _ActionButton(
                    icon: Icons.local_offer_outlined,
                    label: "Discount",
                    onTap: () async {
                      final selectedTable = ref.read(selectedTableNameProvider);
                      await _openCheckoutDialog(
                        context: context,
                        ref: ref,
                        items: cartItems,
                        subtotal: total,
                        tableName: selectedTable,
                        isDarkMode: isDarkMode,
                        intent: CheckoutIntent.discount,
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),
                  _ActionButton(
                    icon: Icons.note_add_outlined,
                    label: "Note",
                    onTap: () => _showDummyFeature(context, "Add Note", isDarkMode),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Neon Glow Button Container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: cartItems.isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 1, // Neon glow effect
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                final selectedTable = ref.read(selectedTableNameProvider);
                                if (selectedTable != null) {
                                  await _submitOrder(
                                    context: context,
                                    ref: ref,
                                    items: cartItems,
                                    total: total,
                                    tableName: selectedTable,
                                    orderType: OrderType.dineIn,
                                  );
                                } else {
                                  await _chooseOrderTypeDialog(
                                  context: context,
                                  ref: ref,
                                  items: cartItems,
                                  total: total,
                                  isDarkMode: isDarkMode,
                                );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0, // Remove default elevation to use custom glow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "PLACE ORDER",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDummyFeature(BuildContext context, String feature, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(24),
          color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
          width: 300,
          border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction, color: AppColors.accent, size: 48),
                const SizedBox(height: 16),
                Text(
                  "$feature",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This feature is available in the full version.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt({
    required List<CartItemModel> items,
    required double total,
    String? tableName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("RESTAURANT POS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
              ),
              pw.Center(
                child: pw.Text("Original Taste", style: const pw.TextStyle(fontSize: 16)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              if (tableName != null)
                pw.Text("Table: $tableName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text("Date: ${DateTime.now().toString().split('.')[0]}"),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              
              // Items
              ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text("${item.quantity}x ${item.menuItem.name}"),
                  ),
                  pw.Text("\$${(item.menuItem.price * item.quantity).toStringAsFixed(2)}"),
                ],
              )),
              
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                  pw.Text("\$${total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text("Thank you for dining with us!", style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _chooseOrderTypeDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<CartItemModel> items,
    required double total,
    required bool isDarkMode,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            width: MediaQuery.of(context).size.width > 480 ? 450 : MediaQuery.of(context).size.width * 0.9,
            border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Digital Receipt",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Print Button
                      IconButton(
                        onPressed: () {
                          _printReceipt(items: items, total: total, tableName: null);
                        },
                        icon: Icon(Icons.print, color: isDarkMode ? Colors.white70 : Colors.black54),
                        tooltip: "Print Receipt",
                      ),
                      const SizedBox(width: 4),
                      if (MediaQuery.of(context).size.width > 360)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "New Order",
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 10),
                  
                  // Items List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item.quantity}x ${item.menuItem.name}",
                                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
                              ),
                              Text(
                                "\$${(item.menuItem.price * item.quantity).toStringAsFixed(2)}",
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 10),
                  
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        "\$${total.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final token = ref.read(takeawayTokenProvider);
                            final label = "Takeaway #$token";
                            ref.read(takeawayTokenProvider.notifier).state = token + 1;
                            Navigator.of(ctx).pop();
                            await _submitOrder(
                              context: context,
                              ref: ref,
                              items: items,
                              total: total,
                              tableName: label,
                              orderType: OrderType.takeaway,
                            );
                          },
                          icon: Icon(Icons.shopping_bag, color: isDarkMode ? Colors.white : Colors.black87),
                          label: Text("Takeaway", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200],
                            foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _selectTableDialog(
                              context: context,
                              ref: ref,
                              items: items,
                              total: total,
                              isDarkMode: isDarkMode,
                            );
                          },
                          icon: const Icon(Icons.table_restaurant, color: Colors.black),
                          label: const Text("Dine-In", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
  }

  Future<void> _selectTableDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<CartItemModel> items,
    required double total,
    required bool isDarkMode,
  }) async {
    final tables = ref.read(tableProvider);
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.white.withOpacity(0.95),
            width: 420,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Table",
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final t = tables[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await _submitOrder(
                              context: context,
                              ref: ref,
                              items: items,
                              total: total,
                              tableName: t.name,
                              orderType: OrderType.dineIn,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chair, color: AppColors.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${t.name} • Seats: ${t.seats}" + (t.waiterName != null ? " • ${t.waiterName}" : ""),
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: isDarkMode ? Colors.white54 : Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

  Future<void> _submitOrder({
    required BuildContext context,
    required WidgetRef ref,
    required List<CartItemModel> items,
    required double total,
    required String tableName,
    required OrderType orderType,
  }) async {
    final order = OrderModel(
      id: const Uuid().v4(),
      tableName: tableName,
      items: items,
      status: OrderStatus.pending,
      timestamp: DateTime.now(),
      orderType: orderType,
    );
    
    // 1. Send to KDS
    ref.read(orderProvider.notifier).addOrder(order);
    
    // 2. Record Transaction (Assume paid for now)
    final txn = TransactionModel(
      id: order.id, // Link via ID
      tableLabel: tableName,
      paymentMethod: "Cash", // Default
      total: total,
      time: DateTime.now(),
      status: TransactionStatus.paid,
      cashAmount: total,
      cardAmount: 0,
    );
    ref.read(salesProvider.notifier).addSale(txn);

    // 3. Clear Cart
    ref.read(cartProvider.notifier).clear();
    
    // 4. Show Feedback Dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FeedbackDialog(
        onSubmit: () {
          Navigator.of(ctx).pop();
          // 5. Navigate back to Table Selection
          ref.read(dashboardIndexProvider.notifier).state = 0; // Table Selection
          ref.read(selectedTableNameProvider.notifier).state = null;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Order Placed & Feedback Received!"),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              width: 400,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItemModel item, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        borderRadius: 12,
        color: isDarkMode ? AppColors.surface.withOpacity(0.3) : Colors.black.withOpacity(0.05),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.name,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${item.menuItem.price.toStringAsFixed(2)} x ${item.quantity}",
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => ref.read(cartProvider.notifier).decrementQuantity(item.id),
                  icon: Icon(Icons.remove_circle_outline, color: isDarkMode ? Colors.white54 : Colors.black54),
                ),
                const SizedBox(width: 8),
                Text(
                  item.quantity.toString(),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref.read(cartProvider.notifier).incrementQuantity(item.id),
                  icon: Icon(Icons.add_circle_outline, color: isDarkMode ? Colors.white54 : Colors.black54),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReceipt(BuildContext context, WidgetRef ref, List<CartItemModel> items, double total, String? tableName) {
    final isDarkMode = ref.read(themeProvider);
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            width: 420,
            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: AppColors.accent, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      "Digital Receipt",
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Spacer(),
                    if (tableName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Text(
                          "Table $tableName",
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
                const SizedBox(height: 8),
                ...items.map((ci) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${ci.quantity}x ${ci.menuItem.name}",
                              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          Text(
                            "\$${(ci.menuItem.price * ci.quantity).toStringAsFixed(2)}",
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "\$${total.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          try {
                            await _printReceipt(items: items, total: total, tableName: tableName);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Print failed: $e"), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.print, color: isDarkMode ? Colors.white : Colors.white),
                        label: const Text("Print"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: isDarkMode ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sent to WhatsApp")));
                        },
                        icon: Icon(Icons.message, color: isDarkMode ? Colors.white : Colors.white),
                        label: const Text("Send to WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: isDarkMode ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(ctx).pop();
                      
                      // Create Order
                      final order = OrderModel(
                        id: const Uuid().v4(),
                        tableName: tableName ?? "Unknown",
                        items: items,
                        status: OrderStatus.pending,
                        timestamp: DateTime.now(),
                        orderType: OrderType.dineIn, // Default for now
                      );
                      
                      // Add to Kitchen (Global Orders List)
                      ref.read(orderProvider.notifier).addOrder(order);
                      
                      // Clear Cart
                      ref.read(cartProvider.notifier).clear();
                      
                      // Show Success Message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order Sent to Kitchen Successfully!"),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Redirect to Table Screen
                      ref.read(dashboardIndexProvider.notifier).state = 2; // Index 2 is KDS Screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPrintPreview(
    BuildContext context,
    WidgetRef ref, {
    required List<CartItemModel> items,
    required double total,
    required String? tableName,
  }) async {
    final isDarkMode = ref.read(themeProvider);
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: SizedBox(
            width: 520,
            height: 620,
            child: Material(
              color: Colors.transparent,
              child: GlassContainer(
                borderRadius: 16,
                color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                padding: const EdgeInsets.all(12),
                child: PdfPreview(
                  build: (format) => _buildReceiptPdf(
                    format: format,
                    items: items,
                    total: total,
                    tableName: tableName,
                    discountAmount: 0,
                    taxRatePercent: null,
                    serviceRatePercent: null,
                    tipAmount: 0,
                  ),
                  allowSharing: true,
                  canChangePageFormat: true,
                  initialPageFormat: PdfPageFormat.a5,
                  pdfFileName: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _openCheckoutDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<CartItemModel> items,
    required double subtotal,
    required bool isDarkMode,
    String? tableName,
    CheckoutIntent intent = CheckoutIntent.settle,
  }) async {
    double discountValue = 0;
    String discountType = intent == CheckoutIntent.discount ? "Percent" : "None";
    double taxRate = 10.0;
    double serviceRate = 5.0;
    double tipValue = 0.0;
    bool splitEnabled = intent == CheckoutIntent.split;
    double splitCash = 0.0;
    double splitCard = 0.0;
    String paymentMethod = "Cash";
    
    double computeTotal() {
      final discountAmt = discountType == "Percent"
          ? (subtotal * (discountValue.clamp(0, 100) / 100))
          : (discountType == "Fixed" ? discountValue.clamp(0, subtotal) : 0.0);
      final base = subtotal - discountAmt;
      final taxAmt = base * (taxRate / 100);
      final serviceAmt = base * (serviceRate / 100);
      final tipAmt = tipValue.clamp(0, 100000);
      return base + taxAmt + serviceAmt + tipAmt;
    }
    
    if (splitEnabled) {
      final initialPayable = computeTotal();
      splitCash = double.parse((initialPayable / 2).toStringAsFixed(2));
      splitCard = double.parse((initialPayable - splitCash).toStringAsFixed(2));
    }
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final payable = computeTotal();
          final validSplit = !splitEnabled || (double.parse((splitCash + splitCard).toStringAsFixed(2)) == double.parse(payable.toStringAsFixed(2)));
          
          return Center(
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
              width: 540,
              border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text("Settle Bill", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        if (tableName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: Text(tableName.startsWith("Takeaway") ? tableName : "Table $tableName", style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isDarkMode ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildAmountTile("Subtotal", "\$${subtotal.toStringAsFixed(2)}", isDarkMode),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAmountTile("Payable", "\$${payable.toStringAsFixed(2)}", isDarkMode),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    Row(
                      children: [
                        // Discount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Discount", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: discountType,
                                      dropdownColor: isDarkMode ? AppColors.surface : Colors.white,
                                      items: const [
                                        DropdownMenuItem(value: "None", child: Text("None")),
                                        DropdownMenuItem(value: "Percent", child: Text("% Percent")),
                                        DropdownMenuItem(value: "Fixed", child: Text("Fixed")),
                                      ],
                                      onChanged: (v) => setState(() => discountType = v ?? "None"),
                                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                      iconEnabledColor: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (v) => setState(() => discountValue = double.tryParse(v) ?? 0),
                                      decoration: InputDecoration(
                                        hintText: discountType == "Percent" ? "0-100" : "Amount",
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tax & Service
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tax / Service", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (v) => setState(() => taxRate = double.tryParse(v) ?? 0),
                                      decoration: const InputDecoration(hintText: "Tax %", border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (v) => setState(() => serviceRate = double.tryParse(v) ?? 0),
                                      decoration: const InputDecoration(hintText: "Service %", border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    // Tip
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tip", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                              const SizedBox(height: 6),
                              TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) => setState(() => tipValue = double.tryParse(v) ?? 0),
                                decoration: const InputDecoration(hintText: "Tip amount", border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: splitEnabled,
                                    onChanged: (val) => setState(() {
                                      splitEnabled = val;
                                      if (!splitEnabled) {
                                        splitCash = 0;
                                        splitCard = 0;
                                      }
                                    }),
                                  ),
                                  Text("Split Payment", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                                ],
                              ),
                              if (splitEnabled)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (v) => setState(() => splitCash = double.tryParse(v) ?? 0),
                                        decoration: const InputDecoration(hintText: "Cash \$", border: OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (v) => setState(() => splitCard = double.tryParse(v) ?? 0),
                                        decoration: const InputDecoration(hintText: "Card \$", border: OutlineInputBorder()),
                                      ),
                                    ),
                                  ],
                                ),
                              if (!splitEnabled)
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: paymentMethod,
                                          dropdownColor: isDarkMode ? AppColors.surface : Colors.white,
                                          items: const [
                                            DropdownMenuItem(value: "Cash", child: Text("Cash")),
                                            DropdownMenuItem(value: "Card", child: Text("Card")),
                                          ],
                                          onChanged: (v) => setState(() => paymentMethod = v ?? "Cash"),
                                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                          iconEnabledColor: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: validSplit
                              ? () async {
                                  Navigator.pop(ctx);
                                  try {
                                    await Printing.layoutPdf(
                                      onLayout: (format) => _buildReceiptPdf(
                                        format: format,
                                        items: items,
                                        total: computeTotal(),
                                        tableName: tableName,
                                        discountAmount: discountType == "Percent"
                                            ? (subtotal * (discountValue.clamp(0, 100) / 100))
                                            : (discountType == "Fixed" ? discountValue.clamp(0, subtotal) : 0.0),
                                        taxRatePercent: taxRate,
                                        serviceRatePercent: serviceRate,
                                        tipAmount: tipValue,
                                      ),
                                    );
                                    final cashPortion = splitEnabled ? splitCash : (paymentMethod == "Cash" ? computeTotal() : 0.0);
                                    if (cashPortion > 0) {
                                      ref.read(shiftProvider.notifier).cashIn(amount: cashPortion, note: tableName ?? "Sale");
                                    }
                                    ref.read(salesProvider.notifier).addSale(
                                      TransactionModel(
                                        id: const Uuid().v4(),
                                        tableLabel: tableName ?? "Unknown",
                                        paymentMethod: splitEnabled ? "Split" : paymentMethod,
                                        total: computeTotal(),
                                        time: DateTime.now(),
                                        status: TransactionStatus.paid,
                                        cashAmount: cashPortion,
                                        cardAmount: splitEnabled ? splitCard : (paymentMethod == "Card" ? computeTotal() : 0.0),
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment successful")));
                                    final takeawayToken = ref.read(takeawayTokenProvider);
                                    final effectiveTable = tableName ?? "Takeaway #$takeawayToken";
                                    if (tableName == null) {
                                      ref.read(takeawayTokenProvider.notifier).state = takeawayToken + 1;
                                    }
                                    final order = OrderModel(
                                      id: const Uuid().v4(),
                                      tableName: effectiveTable,
                                      items: items,
                                      status: OrderStatus.pending,
                                      timestamp: DateTime.now(),
                                      orderType: tableName != null ? OrderType.dineIn : OrderType.takeaway,
                                    );
                                    ref.read(orderProvider.notifier).addOrder(order);
                                    ref.read(cartProvider.notifier).clear();
                                    ref.read(dashboardIndexProvider.notifier).state = 2;
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print failed: $e"), backgroundColor: AppColors.error));
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.print),
                          label: const Text("Finalize + Print"),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                        ),
                      ],
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
  
  Widget _buildAmountTile(String title, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Future<Uint8List> _buildReceiptPdf({
    required PdfPageFormat format,
    required List<CartItemModel> items,
    required double total,
    required String? tableName,
    double? discountAmount,
    double? taxRatePercent,
    double? serviceRatePercent,
    double? tipAmount,
  }) async {
    final doc = pw.Document();
    final gold = PdfColor.fromInt(0xFFFFC107);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Restaurant POS",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("Digital Receipt", style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (tableName != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: gold, width: 1),
                          ),
                          child: pw.Text(
                            tableName.startsWith("Takeaway") ? tableName : "Table $tableName",
                            style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "Order: ${tableName != null && tableName.startsWith("Takeaway") ? "Takeaway" : "Dine-In"}",
                        style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFFCCCCCC)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              ...items.map((ci) {
                final lineTotal = ci.menuItem.price * ci.quantity;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text("${ci.quantity}x ${ci.menuItem.name}")),
                      pw.Text("\$${lineTotal.toStringAsFixed(2)}"),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: gold),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              if (discountAmount != null && discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Discount", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("-\$${discountAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              if (taxRatePercent != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Tax (${taxRatePercent.toStringAsFixed(1)}%)", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("\$${(total * (taxRatePercent / 100)).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              if (serviceRatePercent != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Service (${serviceRatePercent.toStringAsFixed(1)}%)", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("\$${(total * (serviceRatePercent / 100)).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              if (tipAmount != null && tipAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Tip", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("\$${tipAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text("Thank you!", style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
