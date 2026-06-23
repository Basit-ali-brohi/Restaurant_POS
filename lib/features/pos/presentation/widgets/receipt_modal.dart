import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr/qr.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../../core/pdf/pdf_view.dart';
import '../../domain/models/pos_models.dart';

/// Builds a boolean module matrix for a mock payment-verification QR.
List<List<bool>> _qrMatrix(String data) {
  final code =
      QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
  final image = QrImage(code);
  final n = image.moduleCount;
  return List.generate(
      n, (r) => List.generate(n, (c) => image.isDark(r, c)));
}

/// Styled modal simulating an itemised ESC/POS thermal receipt. Renders on a
/// white "paper" surface in monospace — independent of app theme — exactly as a
/// 80mm thermal printer would emit.
class ReceiptModal extends StatelessWidget {
  const ReceiptModal({super.key, required this.record});

  final OrderRecord record;

  static Future<void> show(BuildContext context, OrderRecord record) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ReceiptModal(record: record),
    );
  }

  static const Color _ink = Color(0xFF111111);
  static const Color _faint = Color(0xFF6B6B6B);
  static const Color _paper = Color(0xFFFBFBF8);

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  String _timestamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 14)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                  child: _paperBody(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _paperBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text('CloudPOS Pro',
              style: _mono(16, weight: FontWeight.w700, spacing: 1.5)),
        ),
        const SizedBox(height: 4),
        Center(child: Text('Fine Dining & Bar', style: _mono(11, color: _faint))),
        const SizedBox(height: 2),
        Center(
            child: Text('12 Gold Street · +1 555 0192',
                style: _mono(10, color: _faint))),
        const SizedBox(height: 12),
        const _DashedLine(),
        const SizedBox(height: 8),
        _kv('BILL', '#${record.billNumber}'),
        _kv('DATE', _timestamp(record.createdAt)),
        _kv('CHANNEL', record.orderType.label),
        if (record.tableName != null) _kv('TABLE', record.tableName!),
        _kv('CASHIER', 'Admin'),
        const SizedBox(height: 8),
        const _DashedLine(),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('ITEM', style: _mono(11, weight: FontWeight.w700))),
            SizedBox(
              width: 34,
              child: Text('QTY',
                  textAlign: TextAlign.right,
                  style: _mono(11, weight: FontWeight.w700)),
            ),
            SizedBox(
              width: 66,
              child: Text('AMOUNT',
                  textAlign: TextAlign.right,
                  style: _mono(11, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _DashedLine(),
        const SizedBox(height: 6),
        for (final line in record.lines) _itemBlock(line),
        const SizedBox(height: 2),
        const _DashedLine(),
        const SizedBox(height: 8),
        _totalRow('Subtotal', _money(record.breakdown.subtotal)),
        if (record.breakdown.discount > 0)
          _totalRow('Discount', '-${_money(record.breakdown.discount)}'),
        for (final tax in record.breakdown.taxes)
          _totalRow(
              '${tax.label} (${(tax.rate * 100).toStringAsFixed(1)}%)',
              _money(tax.amount)),
        if (record.breakdown.serviceCharge > 0)
          _totalRow('Service (10%)', _money(record.breakdown.serviceCharge)),
        if (record.breakdown.packagingFee > 0)
          _totalRow('Packaging', _money(record.breakdown.packagingFee)),
        if (record.breakdown.deliveryFee > 0)
          _totalRow('Delivery', _money(record.breakdown.deliveryFee)),
        if (record.breakdown.roundOff != 0)
          _totalRow('Round Off',
              '${record.breakdown.roundOff >= 0 ? '+' : ''}${_money(record.breakdown.roundOff)}'),
        const SizedBox(height: 6),
        const _DashedLine(),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
                child: Text('GRAND TOTAL',
                    style: _mono(15, weight: FontWeight.w800))),
            Text(_money(record.breakdown.grandTotal),
                style: _mono(15, weight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        Text('${record.breakdown.itemCount} item(s)',
            style: _mono(10, color: _faint)),
        if (record.payment != null) ...[
          const SizedBox(height: 10),
          const _DashedLine(),
          const SizedBox(height: 6),
          for (final tender in record.payment!.tenders)
            _totalRow('Paid · ${tender.method.label}', _money(tender.amount)),
          _totalRow('Tendered', _money(record.payment!.tendered)),
          _totalRow('Change', _money(record.payment!.change)),
        ],
        const SizedBox(height: 14),
        const _DashedLine(),
        const SizedBox(height: 12),
        Center(
            child: Text('THANK YOU — PLEASE VISIT AGAIN',
                style: _mono(11, weight: FontWeight.w700))),
        const SizedBox(height: 6),
        Center(child: Text('GST: 22ABCDE1234F1Z5', style: _mono(9, color: _faint))),
        const SizedBox(height: 12),
        // Verified mock payment QR.
        Center(
          child: _Qr(
            matrix: _qrMatrix(
                'CPOS|BILL:${record.billNumber}|AMT:${record.breakdown.grandTotal.toStringAsFixed(2)}|${record.createdAt.millisecondsSinceEpoch}'),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text('Scan to verify payment', style: _mono(9, color: _faint))),
        const SizedBox(height: 2),
        Center(
            child: Text('*${record.billNumber}*',
                style: _mono(11, color: _faint, spacing: 2))),
      ],
    );
  }

  Widget _itemBlock(OrderLine line) {
    final hasMeta = line.variation != null || line.modifiers.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(line.name, style: _mono(12, weight: FontWeight.w600))),
              SizedBox(
                width: 34,
                child: Text('${line.quantity}',
                    textAlign: TextAlign.right, style: _mono(12)),
              ),
              SizedBox(
                width: 66,
                child: Text(_money(line.lineTotal),
                    textAlign: TextAlign.right,
                    style: _mono(12, weight: FontWeight.w600)),
              ),
            ],
          ),
          if (hasMeta)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                _metaLine(line),
                style: _mono(10, color: _faint),
              ),
            ),
          Text('  @ ${_money(line.unitPrice)} each', style: _mono(10, color: _faint)),
        ],
      ),
    );
  }

  String _metaLine(OrderLine line) {
    final parts = <String>[];
    if (line.variation != null) parts.add(line.variation!);
    parts.addAll(line.modifiers);
    return '  ‹ ${parts.join(', ')} ›';
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(width: 78, child: Text(k, style: _mono(11, color: _faint))),
          Expanded(child: Text(v, style: _mono(11))),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _mono(12))),
          Text(value, style: _mono(12)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => PdfViewer.show(
                context,
                title: 'Receipt #${record.billNumber}',
                fileName: 'receipt_${record.billNumber}.pdf',
                build: (format) => PdfService.buildReceipt(record),
              ),
              icon: const Icon(Icons.print, size: 18, color: Colors.white),
              label: const Text('Print / PDF',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _mono(double size,
      {FontWeight weight = FontWeight.w400,
      Color color = _ink,
      double spacing = 0}) {
    return GoogleFonts.robotoMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: 1.25,
    );
  }
}

/// A printed dashed separator line.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedPainter(), size: const Size(double.infinity, 1)),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A real QR code rendered from a module matrix.
class _Qr extends StatelessWidget {
  const _Qr({required this.matrix});
  final List<List<bool>> matrix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      color: Colors.white,
      child: SizedBox(
        width: 104,
        height: 104,
        child: CustomPaint(painter: _QrPainter(matrix)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.matrix);
  final List<List<bool>> matrix;

  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.length;
    if (n == 0) return;
    final cell = size.width / n;
    final paint = Paint()..color = const Color(0xFF111111);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell + 0.5, cell + 0.5),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.matrix != matrix;
}
