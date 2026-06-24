import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';

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

  final _db = DbService.instance;

  static String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows = await _db.rows('SELECT * FROM sales ORDER BY time DESC');
    state = [
      for (final r in rows)
        TransactionModel(
          id: r['id'] ?? '',
          tableLabel: r['table_label'] ?? '',
          paymentMethod: r['payment_method'] ?? '',
          total: double.tryParse(r['total'] ?? '') ?? 0,
          time: DateTime.tryParse(r['time'] ?? '') ?? DateTime.now(),
          status: TransactionModel._parseStatus(r['status'] ?? 'paid'),
          cashAmount: double.tryParse(r['cash_amount'] ?? '') ?? 0,
          cardAmount: double.tryParse(r['card_amount'] ?? '') ?? 0,
        ),
    ];
  }

  Future<void> _upsert(TransactionModel t) => _db.exec(
        'INSERT INTO sales (id,table_label,payment_method,total,time,status,cash_amount,card_amount) '
        'VALUES (:id,:tl,:pm,:total,:time,:status,:cash,:card) '
        'ON DUPLICATE KEY UPDATE status=:status',
        {
          'id': t.id,
          'tl': t.tableLabel,
          'pm': t.paymentMethod,
          'total': t.total,
          'time': _fmt(t.time),
          'status': t.status.name,
          'cash': t.cashAmount,
          'card': t.cardAmount,
        },
      );

  void addSale(TransactionModel txn) {
    state = [txn, ...state];
    _upsert(txn);
  }

  void refund(String id) {
    TransactionModel? changed;
    state = [
      for (final t in state)
        if (t.id == id)
          (changed = t.copyWith(status: TransactionStatus.refunded))
        else
          t,
    ];
    if (changed != null) _upsert(changed);
  }
}
