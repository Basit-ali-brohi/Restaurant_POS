import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../kitchen/presentation/providers/orders_history_provider.dart';
import '../../../kitchen/presentation/providers/kitchen_provider.dart';
import '../../../kitchen/domain/models/order_model.dart';
import '../providers/sales_provider.dart';
import '../../../cart/domain/models/cart_item_model.dart';
import 'package:uuid/uuid.dart';

class OrdersHistoryScreen extends ConsumerStatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  ConsumerState<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends ConsumerState<OrdersHistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final timelines = ref.watch(ordersTimelineProvider);
    final sales = ref.watch(salesProvider); // Watch sales for payment status

    final filtered = timelines.where((t) {
      // Filter: Show only Ready or Completed orders as per request
      // "Jab KDS par 'Mark Ready' click ho, toh wo order yahan move ho jaye"
      if (t.snapshot.status == OrderStatus.pending || t.snapshot.status == OrderStatus.cooking) {
        return false;
      }

      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return t.snapshot.id.toLowerCase().contains(q) ||
          t.snapshot.tableName.toLowerCase().contains(q) ||
          t.snapshot.orderType.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;
          final isMobile = constraints.maxWidth < 600;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Orders History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassContainer(
                            width: double.infinity,
                            height: 50,
                            borderRadius: 12,
                            color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => setState(() => _query = v),
                                    decoration: InputDecoration(
                                      hintText: "Search order / table / type…",
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            "Orders History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          GlassContainer(
                            width: constraints.maxWidth < 1100 ? 200 : 320,
                            height: 50,
                            borderRadius: 12,
                            color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => setState(() => _query = v),
                                    decoration: InputDecoration(
                                      hintText: "Search order / table / type…",
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(14),
                  color: isDarkMode ? AppColors.surface.withOpacity(0.35) : Colors.white.withOpacity(0.65),
                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            "No order history yet",
                            style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                          itemBuilder: (context, index) {
                            final tl = filtered[index];
                            // Find linked transaction
                            final txn = sales.firstWhere(
                              (s) => s.id == tl.snapshot.id,
                              orElse: () => TransactionModel(
                                id: '',
                                tableLabel: '',
                                paymentMethod: '',
                                total: 0,
                                time: DateTime.now(),
                                status: TransactionStatus.paid, // Default to paid if not found for UI safety, or handle null
                                cashAmount: 0,
                                cardAmount: 0,
                              ),
                            );
                            
                            // Check if transaction exists (id not empty)
                            final hasTxn = txn.id.isNotEmpty;
                            final isPaid = hasTxn && txn.status == TransactionStatus.paid;

                            return _TimelineCard(
                              timeline: tl,
                              isDarkMode: isDarkMode,
                              isSmallScreen: isSmallScreen,
                              isPaid: isPaid,
                              totalAmount: hasTxn ? txn.total : tl.snapshot.items.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity)),
                              onVoid: () => _logPrompt(context, tl.snapshot.id, isDarkMode, type: OrderEventType.voided),
                              onCancel: () => _logPrompt(context, tl.snapshot.id, isDarkMode, type: OrderEventType.canceled),
                              onResend: () => _resendToKDS(context, tl),
                              onReprint: () {
                                final total = hasTxn ? txn.total : tl.snapshot.items.fold(0.0, (sum, item) => sum + (item.menuItem.price * item.quantity));
                                _printReceipt(tl.snapshot.items, total, tl.snapshot.tableName);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logPrompt(BuildContext context, String orderId, bool isDarkMode, {required OrderEventType type}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                width: isSmallScreen ? constraints.maxWidth * 0.9 : 420,
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(type == OrderEventType.voided ? Icons.block : Icons.cancel, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type == OrderEventType.voided ? "Void Order" : "Cancel Order",
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: "Reason / note", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              HapticFeedback.lightImpact();
                              final note = controller.text.trim();
                              final notifier = ref.read(ordersTimelineProvider.notifier);
                              if (type == OrderEventType.voided) {
                                notifier.logVoid(orderId, note);
                              } else {
                                notifier.logCancel(orderId, note);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log added")));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                            child: const Text("Save"),
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

  Future<void> _resendToKDS(BuildContext context, OrderTimeline tl) async {
    final notifier = ref.read(kitchenProvider.notifier);
    final history = ref.read(ordersTimelineProvider.notifier);
    final newOrder = OrderModel(
      id: const Uuid().v4(),
      tableName: tl.snapshot.tableName,
      items: tl.snapshot.items,
      status: OrderStatus.pending,
      timestamp: DateTime.now(),
      orderType: tl.snapshot.orderType,
    );
    notifier.addOrder(newOrder);
    history.logResent(tl.snapshot.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order re-sent to KDS")));
  }
  Future<void> _printReceipt(List<CartItemModel> items, double total, String tableName) async {
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
                child: pw.Text("Copy Receipt", style: const pw.TextStyle(fontSize: 16)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
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
                child: pw.Text("Thank you!", style: const pw.TextStyle(fontSize: 12)),
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
}

class _TimelineCard extends StatelessWidget {
  final OrderTimeline timeline;
  final bool isDarkMode;
  final bool isSmallScreen;
  final bool isPaid;
  final double totalAmount;
  final VoidCallback onVoid;
  final VoidCallback onCancel;
  final VoidCallback onResend;
  final VoidCallback onReprint;
  const _TimelineCard({
    required this.timeline,
    required this.isDarkMode,
    required this.isSmallScreen,
    required this.isPaid,
    required this.totalAmount,
    required this.onVoid,
    required this.onCancel,
    required this.onResend,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (timeline.snapshot.status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.cooking => Colors.blue,
      OrderStatus.ready => Colors.green,
      OrderStatus.completed => Colors.grey,
    };

    final headerRow = isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.18), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor)),
                    child: Text(timeline.snapshot.status.name.toUpperCase(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Text("#${timeline.snapshot.id.substring(0, 6)}", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(timeline.snapshot.tableName, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue : Colors.purple),
                    ),
                    child: Text(
                      timeline.snapshot.orderType == OrderType.takeaway ? "Takeaway" : "Dine-In",
                      style: TextStyle(color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue : Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  // Paid/Unpaid Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isPaid ? AppColors.success : AppColors.error),
                    ),
                    child: Text(
                      isPaid ? "PAID" : "UNPAID",
                      style: TextStyle(color: isPaid ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("Total: \$${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            ],
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.18), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor)),
                child: Text(timeline.snapshot.status.name.toUpperCase(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(timeline.snapshot.tableName, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue : Colors.purple),
                ),
                child: Text(
                  timeline.snapshot.orderType == OrderType.takeaway ? "Takeaway" : "Dine-In",
                  style: TextStyle(color: timeline.snapshot.orderType == OrderType.takeaway ? Colors.blue : Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              // Paid/Unpaid Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPaid ? AppColors.success : AppColors.error),
                ),
                child: Text(
                  isPaid ? "PAID" : "UNPAID",
                  style: TextStyle(color: isPaid ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text("Total: \$${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              const Spacer(),
              Text("#${timeline.snapshot.id.substring(0, 6)}", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
            ],
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerRow,
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              for (final ev in timeline.events)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(_iconFor(ev.type), color: _colorFor(ev.type), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _labelFor(ev),
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      const Spacer(),
                      Text(
                        "${ev.time.hour.toString().padLeft(2, '0')}:${ev.time.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final actions = [
      ElevatedButton.icon(
        onPressed: onReprint,
        icon: const Icon(Icons.print),
        label: const Text("Re-print Receipt"),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
      ),
      const SizedBox(height: 8, width: 8),
      ElevatedButton.icon(
        onPressed: onResend,
        icon: const Icon(Icons.send),
        label: const Text("Re-send KDS"),
        style: ElevatedButton.styleFrom(backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200], foregroundColor: isDarkMode ? Colors.white : Colors.black87),
      ),
      const SizedBox(height: 8, width: 8),
      ElevatedButton.icon(
        onPressed: onVoid,
        icon: const Icon(Icons.block),
        label: const Text("Void Log"),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
      ),
      const SizedBox(height: 8, width: 8),
      ElevatedButton.icon(
        onPressed: onCancel,
        icon: const Icon(Icons.cancel),
        label: const Text("Cancel Log"),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.8), foregroundColor: Colors.white),
      ),
    ];

    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actions,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: content),
          const SizedBox(width: 12),
          Column(
            children: actions,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(OrderEventType t) {
    switch (t) {
      case OrderEventType.created:
        return Icons.receipt_long;
      case OrderEventType.statusChanged:
        return Icons.autorenew;
      case OrderEventType.completed:
        return Icons.check_circle;
      case OrderEventType.voided:
        return Icons.block;
      case OrderEventType.canceled:
        return Icons.cancel;
      case OrderEventType.resent:
        return Icons.send;
    }
  }

  Color _colorFor(OrderEventType t) {
    switch (t) {
      case OrderEventType.created:
        return Colors.blue;
      case OrderEventType.statusChanged:
        return Colors.orange;
      case OrderEventType.completed:
        return Colors.green;
      case OrderEventType.voided:
        return AppColors.error;
      case OrderEventType.canceled:
        return AppColors.error;
      case OrderEventType.resent:
        return AppColors.accent;
    }
  }

  String _labelFor(TimelineEvent ev) {
    switch (ev.type) {
      case OrderEventType.created:
        return "KOT created";
      case OrderEventType.statusChanged:
        return "Status → ${ev.newStatus?.name}";
      case OrderEventType.completed:
        return "Order completed";
      case OrderEventType.voided:
        return "Voided • ${ev.note ?? ''}";
      case OrderEventType.canceled:
        return "Canceled • ${ev.note ?? ''}";
      case OrderEventType.resent:
        return "Re-sent to KDS";
    }
  }
}
