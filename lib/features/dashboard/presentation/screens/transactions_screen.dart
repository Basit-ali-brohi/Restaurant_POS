import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/sales_provider.dart';
import '../providers/shift_provider.dart';

enum _TxnRange { today, week, month }

enum _TxnStatus { all, paid, refunded, unpaid }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _TxnRange _range = _TxnRange.today;
  _TxnStatus _status = _TxnStatus.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final sales = ref.watch(salesProvider);
    final all = sales.map((s) {
      return _Txn(
        id: s.id,
        tableLabel: s.tableLabel,
        paymentMethod: s.paymentMethod,
        status: switch (s.status) {
          TransactionStatus.paid => _TxnStatus.paid,
          TransactionStatus.refunded => _TxnStatus.refunded,
          TransactionStatus.unpaid => _TxnStatus.unpaid,
          _ => _TxnStatus.paid,
        },
        total: s.total,
        timeLabel: "${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}",
        cashAmount: s.cashAmount,
        cardAmount: s.cardAmount,
      );
    }).toList();

    final filtered = all.where((t) {
      if (_status != _TxnStatus.all && t.status != _status) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return t.id.toLowerCase().contains(q) ||
          t.tableLabel.toLowerCase().contains(q) ||
          t.paymentMethod.toLowerCase().contains(q);
    }).toList();

    final rangeLabel = switch (_range) {
      _TxnRange.today => 'Today',
      _TxnRange.week => 'This Week',
      _TxnRange.month => 'This Month',
    };

    final double totalSales = filtered
        .where((t) => t.status == _TxnStatus.paid)
        .fold<double>(0, (sum, t) => sum + t.total);
    final int totalOrders = filtered.length;
    final int refunds = filtered.where((t) => t.status == _TxnStatus.refunded).length;

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Transactions",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.accent),
                                ),
                                child: Text(
                                  rangeLabel,
                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GlassContainer(
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
                                      hintText: "Search...",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                    ),
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (_query.trim().isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _query = '');
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white54 : Colors.black54),
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
                            "Transactions",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: Text(
                              rangeLabel,
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
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
                                      hintText: "Search receipt / table / payment…",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                    ),
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (_query.trim().isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _query = '');
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white54 : Colors.black54),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: isMobile
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _RangeChip(
                              label: "Today",
                              selected: _range == _TxnRange.today,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(() => _range = _TxnRange.today),
                            ),
                            const SizedBox(width: 10),
                            _RangeChip(
                              label: "Week",
                              selected: _range == _TxnRange.week,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(() => _range = _TxnRange.week),
                            ),
                            const SizedBox(width: 10),
                            _RangeChip(
                              label: "Month",
                              selected: _range == _TxnRange.month,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(() => _range = _TxnRange.month),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<_TxnStatus>(
                                  value: _status,
                                  dropdownColor: isDarkMode ? AppColors.surface : Colors.white,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    HapticFeedback.lightImpact();
                                    setState(() => _status = v);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: _TxnStatus.all, child: Text("All Status")),
                                    DropdownMenuItem(value: _TxnStatus.paid, child: Text("Paid")),
                                    DropdownMenuItem(value: _TxnStatus.refunded, child: Text("Refunded")),
                                    DropdownMenuItem(value: _TxnStatus.unpaid, child: Text("Unpaid")),
                                  ],
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                                  iconEnabledColor: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          _RangeChip(
                            label: "Today",
                            selected: _range == _TxnRange.today,
                            isDarkMode: isDarkMode,
                            onTap: () => setState(() => _range = _TxnRange.today),
                          ),
                          const SizedBox(width: 10),
                          _RangeChip(
                            label: "Week",
                            selected: _range == _TxnRange.week,
                            isDarkMode: isDarkMode,
                            onTap: () => setState(() => _range = _TxnRange.week),
                          ),
                          const SizedBox(width: 10),
                          _RangeChip(
                            label: "Month",
                            selected: _range == _TxnRange.month,
                            isDarkMode: isDarkMode,
                            onTap: () => setState(() => _range = _TxnRange.month),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<_TxnStatus>(
                                value: _status,
                                dropdownColor: isDarkMode ? AppColors.surface : Colors.white,
                                onChanged: (v) {
                                  if (v == null) return;
                                  HapticFeedback.lightImpact();
                                  setState(() => _status = v);
                                },
                                items: const [
                                    DropdownMenuItem(value: _TxnStatus.all, child: Text("All Status")),
                                    DropdownMenuItem(value: _TxnStatus.paid, child: Text("Paid")),
                                    DropdownMenuItem(value: _TxnStatus.refunded, child: Text("Refunded")),
                                    DropdownMenuItem(value: _TxnStatus.unpaid, child: Text("Unpaid")),
                                  ],
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                                iconEnabledColor: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _SummaryPill(
                            label: "Sales",
                            value: "\$${totalSales.toStringAsFixed(2)}",
                            icon: Icons.payments,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 10),
                          _SummaryPill(
                            label: "Orders",
                            value: "$totalOrders",
                            icon: Icons.receipt_long,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 10),
                          _SummaryPill(
                            label: "Refunds",
                            value: "$refunds",
                            icon: Icons.undo,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
              ),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryPill(
                        label: "Sales",
                        value: "\$${totalSales.toStringAsFixed(2)}",
                        icon: Icons.payments,
                        isDarkMode: isDarkMode,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      _SummaryPill(
                        label: "Orders",
                        value: "$totalOrders",
                        icon: Icons.receipt_long,
                        isDarkMode: isDarkMode,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      _SummaryPill(
                        label: "Refunds",
                        value: "$refunds",
                        icon: Icons.undo,
                        isDarkMode: isDarkMode,
                        fullWidth: true,
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
                  child: Column(
                    children: [
                      if (!isMobile) ...[
                        _HeaderRow(isDarkMode: isDarkMode),
                        Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                      ],
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "No transactions found",
                                  style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                                itemBuilder: (context, index) {
                                  final txn = filtered[index];
                                  if (isMobile) {
                                    return _MobileTransactionCard(
                                      txn: txn,
                                      isDarkMode: isDarkMode,
                                      onView: () => _showReceiptPreview(context, txn, isDarkMode),
                                      onRefund: txn.status == _TxnStatus.refunded
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              ref.read(salesProvider.notifier).refund(txn.id);
                                              if (txn.cashAmount > 0) {
                                                ref.read(shiftProvider.notifier).cashOut(amount: txn.cashAmount, note: "Refund ${txn.id.substring(0,6)}");
                                              }
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refund issued")));
                                            },
                                    );
                                  }
                                  return _TransactionRow(
                                    txn: txn,
                                    isDarkMode: isDarkMode,
                                    onView: () => _showReceiptPreview(context, txn, isDarkMode),
                                    onRefund: txn.status == _TxnStatus.refunded
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            ref.read(salesProvider.notifier).refund(txn.id);
                                            if (txn.cashAmount > 0) {
                                              ref.read(shiftProvider.notifier).cashOut(amount: txn.cashAmount, note: "Refund ${txn.id.substring(0,6)}");
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refund issued")));
                                          },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReceiptPreview(BuildContext context, _Txn txn, bool isDarkMode) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: GlassContainer(
                width: isSmallScreen ? constraints.maxWidth * 0.9 : 520,
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Receipt ${txn.id}",
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isSmallScreen) ...[
                            const SizedBox(width: 10),
                            _StatusBadge(status: txn.status, isDarkMode: isDarkMode),
                          ],
                        ],
                      ),
                      if (isSmallScreen) ...[
                        const SizedBox(height: 8),
                        _StatusBadge(status: txn.status, isDarkMode: isDarkMode),
                      ],
                      const SizedBox(height: 12),
                      Divider(color: isDarkMode ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 10),
                      _kv("Table / Type", txn.tableLabel, isDarkMode),
                      _kv("Payment", txn.paymentMethod, isDarkMode),
                      _kv("Time", txn.timeLabel, isDarkMode),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "\$${txn.total.toStringAsFixed(2)}",
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await Printing.layoutPdf(onLayout: (format) => _buildTxnPdf(format, txn));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reprint sent to printer")));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reprint failed: $e"), backgroundColor: AppColors.error));
                              }
                            },
                            icon: Icon(Icons.print, color: isDarkMode ? Colors.white : Colors.white, size: 18),
                            label: const Text("Reprint"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: isDarkMode ? Colors.white : Colors.white,
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
  
  Future<Uint8List> _buildTxnPdf(PdfPageFormat format, _Txn txn) async {
    final doc = pw.Document();
    final gold = PdfColor.fromInt(0xFFFFC107);
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Restaurant POS", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text("Receipt Reprint", style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: gold, width: 1),
                    ),
                    child: pw.Text(
                      txn.tableLabel,
                      style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _kvPdf("Receipt", txn.id),
              _kvPdf("Table / Type", txn.tableLabel),
              _kvPdf("Payment", txn.paymentMethod),
              _kvPdf("Time", txn.timeLabel),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("\$${txn.total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: gold)),
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
  
  pw.Widget _kvPdf(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(k, style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(0xFF777777)))),
          pw.Expanded(child: pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
          ),
          Expanded(
            child: Text(v, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<_Txn> _seedTransactions() {
    final now = DateTime.now();
    return [
      _Txn(id: "R-10452", tableLabel: "Table T2", paymentMethod: "Cash", status: _TxnStatus.paid, total: 120.50, timeLabel: _time(now.subtract(const Duration(minutes: 12))), cashAmount: 120.50, cardAmount: 0),
      _Txn(id: "R-10451", tableLabel: "Takeaway #18", paymentMethod: "Card", status: _TxnStatus.paid, total: 45.00, timeLabel: _time(now.subtract(const Duration(minutes: 28))), cashAmount: 0, cardAmount: 45.00),
      _Txn(id: "R-10450", tableLabel: "Table VIP", paymentMethod: "Cash", status: _TxnStatus.refunded, total: 80.00, timeLabel: _time(now.subtract(const Duration(hours: 1, minutes: 8))), cashAmount: 80.00, cardAmount: 0),
      _Txn(id: "R-10449", tableLabel: "Table T3", paymentMethod: "Card", status: _TxnStatus.paid, total: 62.75, timeLabel: _time(now.subtract(const Duration(hours: 2, minutes: 15))), cashAmount: 0, cardAmount: 62.75),
      _Txn(id: "R-10448", tableLabel: "Takeaway #17", paymentMethod: "Wallet", status: _TxnStatus.paid, total: 33.25, timeLabel: _time(now.subtract(const Duration(hours: 3, minutes: 2))), cashAmount: 0, cardAmount: 0),
    ];
  }

  String _time(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.hour)}:${two(dt.minute)}";
  }
}

class _Txn {
  final String id;
  final String tableLabel;
  final String paymentMethod;
  final _TxnStatus status;
  final double total;
  final String timeLabel;
  final double cashAmount;
  final double cardAmount;

  const _Txn({
    required this.id,
    required this.tableLabel,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.timeLabel,
    required this.cashAmount,
    required this.cardAmount,
  });
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : (isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : (isDarkMode ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? (isDarkMode ? Colors.white : Colors.white) : (isDarkMode ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDarkMode;
  final bool fullWidth;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkMode,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );

    if (fullWidth) {
      content = Expanded(child: content);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          content,
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool isDarkMode;
  const _HeaderRow({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text("Receipt", style: style)),
          SizedBox(width: 140, child: Text("Table / Type", style: style)),
          SizedBox(width: 110, child: Text("Payment", style: style)),
          SizedBox(width: 90, child: Text("Time", style: style)),
          SizedBox(width: 110, child: Text("Status", style: style)),
          const Spacer(),
          SizedBox(width: 90, child: Text("Total", style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 110),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final _Txn txn;
  final bool isDarkMode;
  final VoidCallback onView;
  final VoidCallback? onRefund;

  const _TransactionRow({
    required this.txn,
    required this.isDarkMode,
    required this.onView,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : Colors.black87;
    final secondary = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(txn.id, style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 140, child: Text(txn.tableLabel, style: TextStyle(color: secondary))),
          SizedBox(width: 110, child: Text(txn.paymentMethod, style: TextStyle(color: secondary))),
          SizedBox(width: 90, child: Text(txn.timeLabel, style: TextStyle(color: secondary))),
          SizedBox(width: 110, child: _StatusBadge(status: txn.status, isDarkMode: isDarkMode)),
          const Spacer(),
          SizedBox(
            width: 90,
            child: Text(
              "\$${txn.total.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 98,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onView,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.visibility, size: 18, color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: onRefund == null ? 0.4 : 1,
                  child: InkWell(
                    onTap: onRefund,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (onRefund == null ? Colors.grey : AppColors.error).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: (onRefund == null ? Colors.grey : AppColors.error).withOpacity(0.35)),
                      ),
                      child: Icon(Icons.undo, size: 18, color: onRefund == null ? (isDarkMode ? Colors.white54 : Colors.black38) : AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TxnStatus status;
  final bool isDarkMode;
  const _StatusBadge({required this.status, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _TxnStatus.paid => ("Paid", AppColors.success),
      _TxnStatus.refunded => ("Refunded", AppColors.error),
      _TxnStatus.unpaid => ("Unpaid", AppColors.warning),
      _TxnStatus.all => ("All", AppColors.accent),
      _ => ("Unknown", AppColors.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _MobileTransactionCard extends StatelessWidget {
  final _Txn txn;
  final bool isDarkMode;
  final VoidCallback onView;
  final VoidCallback? onRefund;

  const _MobileTransactionCard({
    required this.txn,
    required this.isDarkMode,
    required this.onView,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : Colors.black87;
    final secondary = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  txn.id,
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: txn.status, isDarkMode: isDarkMode),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  txn.tableLabel,
                  style: TextStyle(color: secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(txn.timeLabel, style: TextStyle(color: secondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(txn.paymentMethod, style: TextStyle(color: secondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "\$${txn.total.toStringAsFixed(2)}",
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Spacer(),
              InkWell(
                onTap: onView,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.visibility, size: 18, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: onRefund == null ? 0.4 : 1,
                child: InkWell(
                  onTap: onRefund,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (onRefund == null ? Colors.grey : AppColors.error).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (onRefund == null ? Colors.grey : AppColors.error).withOpacity(0.35)),
                    ),
                    child: Icon(Icons.undo, size: 18, color: onRefund == null ? (isDarkMode ? Colors.white54 : Colors.black38) : AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
