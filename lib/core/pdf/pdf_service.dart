import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/pos/domain/models/pos_models.dart';
import '../../features/staff_payroll/presentation/providers/payroll_provider.dart';

/// Builds real PDF documents (receipts, payslips) that can be previewed,
/// printed and downloaded from anywhere in the app.
class PdfService {
  PdfService._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF111111);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);
  static const PdfColor _accent = PdfColor.fromInt(0xFF4F46E5);

  static String _money(double v) => 'PKR ${v.toStringAsFixed(2)}';

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // --- Thermal receipt -------------------------------------------------------
  static Future<Uint8List> buildReceipt(OrderRecord o) async {
    final doc = pw.Document();
    final route = o.orderType == OrderType.dineIn && o.tableName != null
        ? 'Table ${o.tableName}'
        : o.orderType.label;

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 70,
                child: pw.Text(k,
                    style: const pw.TextStyle(fontSize: 8, color: _muted))),
            pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 8))),
          ]),
        );

    pw.Widget total(String label, double value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(children: [
            pw.Expanded(
                child: pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: bold ? 11 : 9,
                        fontWeight:
                            bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
            pw.Text(_money(value),
                style: pw.TextStyle(
                    fontSize: bold ? 11 : 9,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ]),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
                child: pw.Text('CloudPOS Pro',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold))),
            pw.Center(
                child: pw.Text('Fine Dining & Bar',
                    style: const pw.TextStyle(fontSize: 8, color: _muted))),
            pw.Center(
                child: pw.Text('12 Gold Street · +1 555 0192',
                    style: const pw.TextStyle(fontSize: 7, color: _muted))),
            pw.Divider(color: _muted),
            kv('BILL', '#${o.billNumber}'),
            kv('DATE', _stamp(o.createdAt)),
            kv('CHANNEL', o.orderType.label),
            if (o.tableName != null) kv('TABLE', o.tableName!),
            pw.Divider(color: _muted),
            for (final line in o.lines) ...[
              pw.Row(children: [
                pw.Expanded(
                    child: pw.Text('${line.quantity}x ${line.name}',
                        style: const pw.TextStyle(fontSize: 9))),
                pw.Text(_money(line.lineTotal),
                    style: const pw.TextStyle(fontSize: 9)),
              ]),
              if (line.variation != null || line.modifiers.isNotEmpty)
                pw.Text(
                    '  ${[if (line.variation != null) line.variation!, ...line.modifiers].join(', ')}',
                    style: const pw.TextStyle(fontSize: 7, color: _muted)),
              pw.SizedBox(height: 2),
            ],
            pw.Divider(color: _muted),
            total('Subtotal', o.breakdown.subtotal),
            for (final tax in o.breakdown.taxes) total(tax.label, tax.amount),
            if (o.breakdown.serviceCharge > 0)
              total('Service', o.breakdown.serviceCharge),
            if (o.breakdown.packagingFee > 0)
              total('Packaging', o.breakdown.packagingFee),
            if (o.breakdown.deliveryFee > 0)
              total('Delivery', o.breakdown.deliveryFee),
            pw.Divider(color: _muted),
            total('TOTAL', o.breakdown.grandTotal, bold: true),
            if (o.payment != null) ...[
              pw.Divider(color: _muted),
              for (final tender in o.payment!.tenders)
                total('Paid · ${tender.method.label}', tender.amount),
              total('Change', o.payment!.change),
            ],
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'CPOS|BILL:${o.billNumber}|AMT:${o.breakdown.grandTotal.toStringAsFixed(2)}',
                width: 80,
                height: 80,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
                child: pw.Text('THANK YOU — PLEASE VISIT AGAIN',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Route: $route', style: const pw.TextStyle(fontSize: 7, color: _muted))),
          ],
        ),
      ),
    );
    return doc.save();
  }

  // --- A4 payslip ------------------------------------------------------------
  static Future<Uint8List> buildPayslip(Employee e) async {
    final doc = pw.Document();

    pw.Widget row(String label, double value, {bool deduction = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(
                child: pw.Text(label, style: const pw.TextStyle(fontSize: 11))),
            pw.Text(
                '${deduction ? '- ' : ''}PKR ${value.abs().toStringAsFixed(0)}',
                style: pw.TextStyle(
                    fontSize: 11,
                    color: deduction
                        ? const PdfColor.fromInt(0xFFC9483F)
                        : _ink)),
          ]),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: const pw.BoxDecoration(color: _accent),
              child: pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CloudPOS Pro',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Management Suite',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Text('PAYSLIP',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(e.name,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('${e.role}   ·   ID: ${e.id}',
                style: const pw.TextStyle(fontSize: 11, color: _muted)),
            pw.Text('Pay period: ${_stamp(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.SizedBox(height: 20),
            pw.Text('EARNINGS',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent)),
            pw.Divider(color: _muted),
            row('Basic Salary', e.basicSalary),
            row('Allowances', e.allowances),
            pw.SizedBox(height: 14),
            pw.Text('DEDUCTIONS',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent)),
            pw.Divider(color: _muted),
            for (final d in e.deductions) row(d.label, d.amount, deduction: true),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF1F1FB),
                  borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(children: [
                pw.Text('NET PAY',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                pw.Text('PKR ${e.netPay.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _accent)),
              ]),
            ),
            pw.Spacer(),
            pw.Center(
                child: pw.Text(
                    'This is a system-generated payslip — CloudPOS Pro',
                    style: const pw.TextStyle(fontSize: 8, color: _muted))),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
