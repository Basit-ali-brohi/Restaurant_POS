import 'package:flutter/material.dart';

// =============================================================================
// STOCK DOMAIN MODELS
// A richer stock line (cost, category, expiry) plus an auditable movement log,
// powering the inventory dashboard, stock adjustments, transfers and recipe
// costing.
// =============================================================================

/// Inventory grouping shown in the dense stock grid filters.
enum StockCategory {
  rawIngredients('Raw Ingredients'),
  produce('Produce'),
  dairyEggs('Dairy & Eggs'),
  dryGoods('Dry Goods'),
  barBeverage('Bar & Beverage'),
  packaging('Packaging');

  const StockCategory(this.label);
  final String label;
}

/// One inventory line with valuation and threshold intelligence.
class StockItem {
  final String id;
  final String name;
  final String sku;
  final StockCategory category;
  final double quantity;
  final String unit;
  final double unitCost;
  final double lowThreshold;
  final double parLevel;
  final DateTime? expiry;

  const StockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.lowThreshold,
    required this.parLevel,
    this.expiry,
  });

  double get valuation => quantity * unitCost;
  bool get isOut => quantity <= 0;
  bool get isLow => quantity > 0 && quantity <= lowThreshold;

  bool isExpiringSoon([DateTime? now]) {
    if (expiry == null) return false;
    final ref = now ?? DateTime.now();
    final days = expiry!.difference(ref).inDays;
    return days <= 4;
  }

  String get statusLabel {
    if (isOut) return 'Out of Stock';
    if (isLow) return 'Low Stock';
    return 'Optimal';
  }

  String get quantityLabel {
    final isInt = quantity % 1 == 0;
    final q = isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
    return '$q $unit';
  }

  StockItem copyWith({double? quantity, double? unitCost, DateTime? expiry}) {
    return StockItem(
      id: id,
      name: name,
      sku: sku,
      category: category,
      quantity: quantity ?? this.quantity,
      unit: unit,
      unitCost: unitCost ?? this.unitCost,
      lowThreshold: lowThreshold,
      parLevel: parLevel,
      expiry: expiry ?? this.expiry,
    );
  }
}

/// Audit movement types. Sign convention: positive deltas add stock.
enum MovementType {
  received('Goods Received', Icons.south_west, Color(0xFF10B981)),
  adjustment('Adjustment', Icons.tune, Color(0xFF3B82F6)),
  wastage('Wastage', Icons.delete_sweep, Color(0xFFEF4444)),
  transferOut('Transfer Out', Icons.north_east, Color(0xFFF59E0B)),
  transferIn('Transfer In', Icons.south_west, Color(0xFF10B981));

  const MovementType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Wastage / loss reason tags for the audit trail.
enum WastageReason {
  spoilage('Spoilage'),
  breakage('Breakage'),
  expired('Expired'),
  overPortion('Over-portioning'),
  theft('Theft / Loss'),
  prepError('Prep Error');

  const WastageReason(this.label);
  final String label;
}

/// An immutable audit record of a single stock movement.
class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final MovementType type;
  final double delta; // +/- in the item's unit
  final String unit;
  final String? reason;
  final String? note;
  final String by;
  final DateTime at;
  final String? fromBranch;
  final String? toBranch;

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.delta,
    required this.unit,
    this.reason,
    this.note,
    required this.by,
    required this.at,
    this.fromBranch,
    this.toBranch,
  });

  String get deltaLabel {
    final sign = delta >= 0 ? '+' : '';
    final isInt = delta % 1 == 0;
    final v = isInt ? delta.toInt().toString() : delta.toStringAsFixed(1);
    return '$sign$v $unit';
  }
}
