import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum TransactionStatus { paid, refunded, unpaid }

class TransactionModel {
  final String id;
  final String tableLabel;
  final String paymentMethod;
  final double total;
  final DateTime time;
  final TransactionStatus status;
  final double cashAmount;
  final double cardAmount;

  const TransactionModel({
    required this.id,
    required this.tableLabel,
    required this.paymentMethod,
    required this.total,
    required this.time,
    required this.status,
    required this.cashAmount,
    required this.cardAmount,
  });

  TransactionModel copyWith({
    String? id,
    String? tableLabel,
    String? paymentMethod,
    double? total,
    DateTime? time,
    TransactionStatus? status,
    double? cashAmount,
    double? cardAmount,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      tableLabel: tableLabel ?? this.tableLabel,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      total: total ?? this.total,
      time: time ?? this.time,
      status: status ?? this.status,
      cashAmount: cashAmount ?? this.cashAmount,
      cardAmount: cardAmount ?? this.cardAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableLabel': tableLabel,
      'paymentMethod': paymentMethod,
      'total': total,
      'time': time.toIso8601String(),
      'status': status.name,
      'cashAmount': cashAmount,
      'cardAmount': cardAmount,
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> m) {
    return TransactionModel(
      id: m['id'] as String,
      tableLabel: m['tableLabel'] as String,
      paymentMethod: m['paymentMethod'] as String,
      total: (m['total'] as num).toDouble(),
      time: DateTime.parse(m['time'] as String),
      status: _parseStatus(m['status'] as String),
      cashAmount: (m['cashAmount'] as num).toDouble(),
      cardAmount: (m['cardAmount'] as num).toDouble(),
    );
  }

  static TransactionStatus _parseStatus(String status) {
    if (status == TransactionStatus.refunded.name) return TransactionStatus.refunded;
    if (status == TransactionStatus.unpaid.name) return TransactionStatus.unpaid;
    return TransactionStatus.paid;
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<TransactionModel>>((ref) {
  return SalesNotifier();
});

class SalesNotifier extends StateNotifier<List<TransactionModel>> {
  SalesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox('sales');
    final List raw = box.get('items', defaultValue: []);
    state = raw.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen('sales') ? Hive.box('sales') : await Hive.openBox('sales');
    await box.put('items', state.map((t) => t.toMap()).toList());
  }

  void addSale(TransactionModel txn) {
    state = [txn, ...state];
    _save();
  }

  void refund(String id) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: TransactionStatus.refunded) else t,
    ];
    _save();
  }
}
