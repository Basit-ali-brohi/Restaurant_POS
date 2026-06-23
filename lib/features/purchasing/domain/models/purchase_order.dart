import 'package:flutter/material.dart';

/// Lifecycle stages of a purchase order (SRS 4.3).
enum POStatus {
  draft('Draft', Color(0xFF94A3B8)),
  pendingApproval('Pending Approval', Color(0xFFF59E0B)),
  approved('Approved', Color(0xFF3B82F6)),
  dispatched('Dispatched', Color(0xFF8B5CF6)),
  received('Received', Color(0xFF10B981)),
  rejected('Rejected', Color(0xFFEF4444));

  const POStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// One requisition line on a purchase order.
class POLine {
  final String itemId;
  final String name;
  final String unit;
  final double quantity;
  final double unitCost;

  const POLine({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitCost,
  });

  double get lineTotal => quantity * unitCost;

  String get qtyLabel {
    final isInt = quantity % 1 == 0;
    final q = isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
    return '$q $unit';
  }
}

/// A purchase order moving through the requisition lifecycle.
class PurchaseOrder {
  final String id;
  final int poNumber;
  final String supplier;
  final List<POLine> lines;
  final POStatus status;
  final DateTime createdAt;
  final String? note;

  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplier,
    required this.lines,
    required this.status,
    required this.createdAt,
    this.note,
  });

  double get total => lines.fold(0.0, (s, l) => s + l.lineTotal);
  int get itemCount => lines.length;

  PurchaseOrder copyWith({POStatus? status}) => PurchaseOrder(
        id: id,
        poNumber: poNumber,
        supplier: supplier,
        lines: lines,
        status: status ?? this.status,
        createdAt: createdAt,
        note: note,
      );
}
