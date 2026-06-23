import 'package:flutter/foundation.dart';

@immutable
class InventoryItemModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double lowThreshold;
  final double maxCapacity;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lowThreshold,
    required this.maxCapacity,
  });

  double get level => (quantity / maxCapacity).clamp(0.0, 1.0);
  String get status => quantity <= lowThreshold ? 'Low' : 'In Stock';
  String get quantityLabel {
    final isInt = quantity % 1 == 0;
    final q = isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
    return "$q $unit";
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    double? lowThreshold,
    double? maxCapacity,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowThreshold: lowThreshold ?? this.lowThreshold,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'lowThreshold': lowThreshold,
      'maxCapacity': maxCapacity,
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      lowThreshold: (map['lowThreshold'] as num).toDouble(),
      maxCapacity: (map['maxCapacity'] as num).toDouble(),
    );
  }
}
