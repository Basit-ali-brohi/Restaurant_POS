import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/db_service.dart';

enum ExpenseCategory {
  rent('Rent & Lease', Color(0xFF6366F1)),
  payroll('Payroll', Color(0xFF10B981)),
  utilities('Utilities', Color(0xFFF59E0B)),
  supplies('Supplies', Color(0xFF3B82F6)),
  marketing('Marketing', Color(0xFFEC4899)),
  maintenance('Maintenance', Color(0xFF8B5CF6)),
  misc('Miscellaneous', Color(0xFF94A3B8));

  const ExpenseCategory(this.label, this.color);
  final String label;
  final Color color;
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final String vendor;
  final double amount;
  final String dateLabel;
  final bool hasInvoice;
  final String invoiceFile; // attached invoice file name (empty = none)

  const Expense({
    required this.id,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.dateLabel,
    required this.hasInvoice,
    this.invoiceFile = '',
  });
}

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super(const []) {
    _load();
  }

  final _db = DbService.instance;

  static const List<Expense> _seed = [
    Expense(id: 'E-1', category: ExpenseCategory.rent, vendor: 'Gulberg Properties', amount: 320000, dateLabel: 'Oct 01', hasInvoice: true),
    Expense(id: 'E-2', category: ExpenseCategory.payroll, vendor: 'Staff Payroll', amount: 481000, dateLabel: 'Oct 01', hasInvoice: true),
    Expense(id: 'E-3', category: ExpenseCategory.utilities, vendor: 'K-Electric', amount: 86400, dateLabel: 'Oct 05', hasInvoice: true),
    Expense(id: 'E-4', category: ExpenseCategory.supplies, vendor: 'Global Spices Co.', amount: 124500, dateLabel: 'Oct 08', hasInvoice: true),
    Expense(id: 'E-5', category: ExpenseCategory.marketing, vendor: 'Meta Ads', amount: 45000, dateLabel: 'Oct 10', hasInvoice: false),
    Expense(id: 'E-6', category: ExpenseCategory.maintenance, vendor: 'CoolTech HVAC', amount: 28000, dateLabel: 'Oct 11', hasInvoice: true),
  ];

  Expense _fromRow(Map<String, String?> r) => Expense(
        id: r['id'] ?? '',
        category: ExpenseCategory.values.firstWhere(
            (c) => c.name == r['category'],
            orElse: () => ExpenseCategory.misc),
        vendor: r['vendor'] ?? '',
        amount: double.tryParse(r['amount'] ?? '') ?? 0,
        dateLabel: r['date_label'] ?? '',
        hasInvoice: (r['has_invoice'] ?? '1') == '1',
        invoiceFile: r['invoice_file'] ?? '',
      );

  Future<void> _load() async {
    if (!_db.isConnected) {
      state = _seed;
      return;
    }
    final rows = await _db.rows('SELECT * FROM expenses');
    if (rows.isEmpty) {
      for (final e in _seed) {
        await _upsert(e);
      }
      state = _seed;
    } else {
      state = rows.map(_fromRow).toList();
    }
  }

  Future<void> _upsert(Expense e) => _db.exec(
        'INSERT INTO expenses (id,category,vendor,amount,date_label,has_invoice,invoice_file) '
        'VALUES (:id,:cat,:vendor,:amount,:date,:inv,:file) '
        'ON DUPLICATE KEY UPDATE category=:cat, vendor=:vendor, amount=:amount, '
        'date_label=:date, has_invoice=:inv, invoice_file=:file',
        {
          'id': e.id,
          'cat': e.category.name,
          'vendor': e.vendor,
          'amount': e.amount,
          'date': e.dateLabel,
          'inv': e.hasInvoice ? 1 : 0,
          'file': e.invoiceFile,
        },
      );

  void addExpense({
    required ExpenseCategory category,
    required String vendor,
    required double amount,
    required bool hasInvoice,
    String invoiceFile = '',
  }) {
    final e = Expense(
      id: const Uuid().v4(),
      category: category,
      vendor: vendor,
      amount: amount,
      dateLabel: 'Today',
      hasInvoice: hasInvoice,
      invoiceFile: invoiceFile,
    );
    state = [e, ...state];
    _upsert(e);
  }

  void updateExpense(
    String id, {
    required ExpenseCategory category,
    required String vendor,
    required double amount,
    required bool hasInvoice,
    String invoiceFile = '',
  }) {
    Expense? changed;
    state = [
      for (final e in state)
        if (e.id == id)
          (changed = Expense(
            id: e.id,
            category: category,
            vendor: vendor,
            amount: amount,
            dateLabel: e.dateLabel,
            hasInvoice: hasInvoice,
            invoiceFile: invoiceFile,
          ))
        else
          e,
    ];
    if (changed != null) _upsert(changed);
  }

  void removeExpense(String id) {
    state = state.where((e) => e.id != id).toList();
    _db.exec('DELETE FROM expenses WHERE id=:id', {'id': id});
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>(
        (ref) => ExpensesNotifier());

/// Total expenses grouped by category.
final expensesByCategoryProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final out = {for (final c in ExpenseCategory.values) c: 0.0};
  for (final e in ref.watch(expensesProvider)) {
    out[e.category] = (out[e.category] ?? 0) + e.amount;
  }
  return out;
});
