import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/shift_provider.dart';
import '../providers/sales_provider.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final shift = ref.watch(shiftProvider);
    final cashIn = ref.watch(shiftCashInTotalProvider);
    final cashOut = ref.watch(shiftCashOutTotalProvider);
    final expectedCash = ref.watch(shiftExpectedCashProvider);
    final variance = shift.closingCash - expectedCash;

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
                                "Shift",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (shift.isOpen ? AppColors.success : AppColors.error).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: shift.isOpen ? AppColors.success : AppColors.error),
                                ),
                                child: Text(
                                  shift.isOpen ? "OPEN" : "CLOSED",
                                  style: TextStyle(color: shift.isOpen ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (!shift.isOpen)
                                  ElevatedButton.icon(
                                    onPressed: () => _openShiftDialog(context, ref, isDarkMode),
                                    icon: const Icon(Icons.lock_open, size: 18),
                                    label: const Text("Open"),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  )
                                else ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      HapticFeedback.lightImpact();
                                      await _printReport(context, ref, title: "X REPORT");
                                    },
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text("X"),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _cashMovementDialog(context, ref, isDarkMode, isIn: true),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text("In"),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _cashMovementDialog(context, ref, isDarkMode, isIn: false),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text("Out"),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _closeShiftDialog(context, ref, isDarkMode),
                                    icon: const Icon(Icons.lock, size: 18),
                                    label: const Text("Close"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            "Shift / Cash Drawer",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (shift.isOpen ? AppColors.success : AppColors.error).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: shift.isOpen ? AppColors.success : AppColors.error),
                            ),
                            child: Text(
                              shift.isOpen ? "OPEN" : "CLOSED",
                              style: TextStyle(color: shift.isOpen ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          if (!shift.isOpen)
                            ElevatedButton.icon(
                              onPressed: () => _openShiftDialog(context, ref, isDarkMode),
                              icon: const Icon(Icons.lock_open),
                              label: const Text("Open Shift"),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            )
                          else ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await _printReport(context, ref, title: "X REPORT");
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Print X"),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _cashMovementDialog(context, ref, isDarkMode, isIn: true),
                              icon: const Icon(Icons.add),
                              label: const Text("Cash In"),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _cashMovementDialog(context, ref, isDarkMode, isIn: false),
                              icon: const Icon(Icons.remove),
                              label: const Text("Cash Out"),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _closeShiftDialog(context, ref, isDarkMode),
                              icon: const Icon(Icons.lock),
                              label: const Text("Close (Z)"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                            ),
                          ],
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
                      if (isMobile)
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          childAspectRatio: 2.0,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _tile("Opening", shift.openingCash, isDarkMode),
                            _tile("Cash In", cashIn, isDarkMode),
                            _tile("Cash Out", cashOut, isDarkMode),
                            _tile("Expected", expectedCash, isDarkMode),
                            _tile("Closing", shift.closingCash, isDarkMode),
                            _tile("Variance", variance, isDarkMode, accent: variance.abs() < 0.01 ? AppColors.success : AppColors.error),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _tile("Opening", shift.openingCash, isDarkMode)),
                            const SizedBox(width: 10),
                            Expanded(child: _tile("Cash In", cashIn, isDarkMode)),
                            const SizedBox(width: 10),
                            Expanded(child: _tile("Cash Out", cashOut, isDarkMode)),
                            const SizedBox(width: 10),
                            Expanded(child: _tile("Expected", expectedCash, isDarkMode)),
                            const SizedBox(width: 10),
                            Expanded(child: _tile("Closing", shift.closingCash, isDarkMode)),
                            const SizedBox(width: 10),
                            Expanded(child: _tile("Variance", variance, isDarkMode, accent: variance.abs() < 0.01 ? AppColors.success : AppColors.error)),
                          ],
                        ),
                      const SizedBox(height: 14),
                      Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 10),
                  Expanded(
                    child: shift.events.isEmpty
                        ? Center(
                            child: Text(
                              "No shift events yet",
                              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          )
                        : ListView.separated(
                            itemCount: shift.events.length,
                            separatorBuilder: (_, __) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                            itemBuilder: (context, index) {
                              final e = shift.events[index];
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _eventColor(e.type).withOpacity(isDarkMode ? 0.18 : 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: _eventColor(e.type).withOpacity(0.65)),
                                    ),
                                    child: Text(
                                      _eventLabel(e.type),
                                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.note.isEmpty ? "-" : e.note,
                                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black45, fontSize: 12),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      "PKR ${e.amount.toStringAsFixed(2)}",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
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
          ),
        ],
      );
    },
  ),
);
  }

  static Widget _tile(String label, double value, bool isDarkMode, {Color? accent}) {
    final color = accent ?? AppColors.accent;
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
          Text(label, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            "PKR ${value.toStringAsFixed(2)}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  static String _eventLabel(ShiftEventType t) {
    switch (t) {
      case ShiftEventType.opened:
        return "OPEN";
      case ShiftEventType.cashIn:
        return "CASH IN";
      case ShiftEventType.cashOut:
        return "CASH OUT";
      case ShiftEventType.closed:
        return "CLOSE";
    }
  }

  static Color _eventColor(ShiftEventType t) {
    switch (t) {
      case ShiftEventType.opened:
        return AppColors.success;
      case ShiftEventType.cashIn:
        return AppColors.success;
      case ShiftEventType.cashOut:
        return AppColors.error;
      case ShiftEventType.closed:
        return Colors.blueGrey;
    }
  }

  Future<void> _openShiftDialog(BuildContext context, WidgetRef ref, bool isDarkMode) async {
    final cashController = TextEditingController();
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            width: 420,
            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text("Open Shift", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: "Opening cash", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(hintText: "Note (optional)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final openingCash = double.tryParse(cashController.text.trim()) ?? 0;
                          ref.read(shiftProvider.notifier).openShift(openingCash: openingCash, note: noteController.text.trim());
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shift opened")));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                        child: const Text("Open"),
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

  Future<void> _cashMovementDialog(BuildContext context, WidgetRef ref, bool isDarkMode, {required bool isIn}) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            width: 420,
            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isIn ? Icons.add : Icons.remove, color: isIn ? AppColors.success : AppColors.error),
                      const SizedBox(width: 8),
                      Text(isIn ? "Cash In" : "Cash Out", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: "Amount", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
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
                          final amount = double.tryParse(amountController.text.trim()) ?? 0;
                          if (amount <= 0) return;
                          if (isIn) {
                            ref.read(shiftProvider.notifier).cashIn(amount: amount, note: noteController.text.trim());
                          } else {
                            ref.read(shiftProvider.notifier).cashOut(amount: amount, note: noteController.text.trim());
                          }
                          Navigator.pop(ctx);
                          HapticFeedback.lightImpact();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: isIn ? AppColors.success : AppColors.error, foregroundColor: Colors.white),
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
  }

  Future<void> _closeShiftDialog(BuildContext context, WidgetRef ref, bool isDarkMode) async {
    final cashController = TextEditingController();
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppColors.surface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            width: 420,
            border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text("Close Shift (Z)", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: "Closing cash", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(hintText: "Note (optional)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final closingCash = double.tryParse(cashController.text.trim()) ?? 0;
                          ref.read(shiftProvider.notifier).closeShift(closingCash: closingCash, note: noteController.text.trim());
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          await _printReport(context, ref, title: "Z REPORT");
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shift closed")));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                        child: const Text("Close + Print"),
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

  Future<void> _printReport(BuildContext context, WidgetRef ref, {required String title}) async {
    try {
      final shift = ref.read(shiftProvider);
      final cashIn = ref.read(shiftCashInTotalProvider);
      final cashOut = ref.read(shiftCashOutTotalProvider);
      final expectedCash = ref.read(shiftExpectedCashProvider);
      final variance = shift.closingCash - expectedCash;
      final sales = ref.read(salesProvider);
      final start = shift.openedAt ?? DateTime.now();
      final end = shift.closedAt ?? DateTime.now();
      final inWindow = sales.where((t) {
        final time = t.time;
        return t.status == TransactionStatus.paid && !time.isBefore(start) && !time.isAfter(end);
      }).toList();
      final cashSales = inWindow.fold<double>(0, (sum, t) => sum + t.cashAmount);
      final cardSales = inWindow.fold<double>(0, (sum, t) => sum + t.cardAmount);
      final totalSales = inWindow.fold<double>(0, (sum, t) => sum + t.total);
      final otherSales = ((totalSales - cashSales - cardSales).clamp(0, double.infinity)).toDouble();
      await Printing.layoutPdf(
        onLayout: (format) => _buildShiftPdf(
          format: format,
          title: title,
          shift: shift,
          cashIn: cashIn,
          cashOut: cashOut,
          expectedCash: expectedCash,
          variance: variance,
          cashSales: cashSales,
          cardSales: cardSales,
          otherSales: otherSales,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print failed: $e"), backgroundColor: AppColors.error));
      }
    }
  }

  Future<Uint8List> _buildShiftPdf({
    required PdfPageFormat format,
    required String title,
    required ShiftState shift,
    required double cashIn,
    required double cashOut,
    required double expectedCash,
    required double variance,
    required double cashSales,
    required double cardSales,
    required double otherSales,
  }) async {
    final doc = pw.Document();
    final accent = PdfColor.fromInt(0xFFFFC107);
    final success = PdfColor.fromInt(0xFF4CAF50);
    final danger = PdfColor.fromInt(0xFFE53935);

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
                      pw.Text("Restaurant POS", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(title, style: pw.TextStyle(fontSize: 12, color: accent)),
                    ],
                  ),
                  pw.Text("Date: ${DateTime.now().toString().split('.')[0]}", style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _pdfKV("Shift Status", shift.isOpen ? "OPEN" : "CLOSED"),
              _pdfKV("Opened At", shift.openedAt?.toString().split('.')[0] ?? "-"),
              _pdfKV("Closed At", shift.closedAt?.toString().split('.')[0] ?? "-"),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _pdfKV("Opening Cash", "PKR ${shift.openingCash.toStringAsFixed(2)}"),
              _pdfKV("Cash In", "PKR ${cashIn.toStringAsFixed(2)}"),
              _pdfKV("Cash Out", "PKR ${cashOut.toStringAsFixed(2)}"),
              _pdfKV("Expected Cash", "PKR ${expectedCash.toStringAsFixed(2)}"),
              _pdfKV("Closing Cash", "PKR ${shift.closingCash.toStringAsFixed(2)}"),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Variance", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    "PKR ${variance.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: variance.abs() < 0.01 ? success : danger),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text("Payment Breakdown", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _pdfKV("Cash Sales", "PKR ${cashSales.toStringAsFixed(2)}"),
              _pdfKV("Card Sales", "PKR ${cardSales.toStringAsFixed(2)}"),
              _pdfKV("Other Sales", "PKR ${otherSales.toStringAsFixed(2)}"),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text("Events", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              ...shift.events.take(30).map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(width: 54, child: pw.Text("${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}", style: const pw.TextStyle(fontSize: 9))),
                      pw.SizedBox(width: 70, child: pw.Text(_pdfEventLabel(e.type), style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(child: pw.Text(e.note.isEmpty ? "-" : e.note, style: const pw.TextStyle(fontSize: 9))),
                      pw.SizedBox(width: 70, child: pw.Text("PKR ${e.amount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfKV(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(v, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _pdfEventLabel(ShiftEventType t) {
    switch (t) {
      case ShiftEventType.opened:
        return "OPEN";
      case ShiftEventType.cashIn:
        return "CASH IN";
      case ShiftEventType.cashOut:
        return "CASH OUT";
      case ShiftEventType.closed:
        return "CLOSE";
    }
  }
}
