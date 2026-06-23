import 'package:flutter/foundation.dart';

@immutable
class SupplierModel {
  final String id;
  final String name;
  final String contact;

  /// SRM 4.4 — supplier relationship metrics.
  final String category; // e.g. Produce, Meat, Dairy, Dry Goods
  final double reliability; // on-time delivery score, 0–100
  final int leadDays; // typical lead time in days
  final double outstandingBalance; // amount we owe this supplier (PKR)

  const SupplierModel({
    required this.id,
    required this.name,
    required this.contact,
    this.category = 'General',
    this.reliability = 95,
    this.leadDays = 2,
    this.outstandingBalance = 0,
  });

  /// Reliability band label used for colour-coding.
  String get reliabilityBand {
    if (reliability >= 95) return 'Excellent';
    if (reliability >= 85) return 'Good';
    if (reliability >= 70) return 'Fair';
    return 'Poor';
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? contact,
    String? category,
    double? reliability,
    int? leadDays,
    double? outstandingBalance,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      category: category ?? this.category,
      reliability: reliability ?? this.reliability,
      leadDays: leadDays ?? this.leadDays,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'category': category,
      'reliability': reliability,
      'leadDays': leadDays,
      'outstandingBalance': outstandingBalance,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as String,
      name: map['name'] as String,
      contact: map['contact'] as String,
      category: (map['category'] as String?) ?? 'General',
      reliability: (map['reliability'] as num?)?.toDouble() ?? 95,
      leadDays: (map['leadDays'] as num?)?.toInt() ?? 2,
      outstandingBalance:
          (map['outstandingBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}

@immutable
class RestockRequest {
  final String id;
  final String itemName;
  final String quantityLabel;
  final DateTime time;
  final String? supplierId;
  final String status;
  final DateTime? resolvedAt;

  const RestockRequest({
    required this.id,
    required this.itemName,
    required this.quantityLabel,
    required this.time,
    this.supplierId,
    required this.status,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantityLabel': quantityLabel,
      'time': time.toIso8601String(),
      'supplierId': supplierId,
      'status': status,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory RestockRequest.fromMap(Map<String, dynamic> map) {
    return RestockRequest(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      quantityLabel: map['quantityLabel'] as String,
      time: DateTime.parse(map['time'] as String),
      supplierId: map['supplierId'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt'] as String) : null,
    );
  }
}
