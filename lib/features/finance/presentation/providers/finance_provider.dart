import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

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

  const Expense({
    required this.id,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.dateLabel,
    required this.hasInvoice,
  });
}

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super(_seed);

  static const List<Expense> _seed = [
    Expense(id: 'E-1', category: ExpenseCategory.rent, vendor: 'Gulberg Properties', amount: 320000, dateLabel: 'Oct 01', hasInvoice: true),
    Expense(id: 'E-2', category: ExpenseCategory.payroll, vendor: 'Staff Payroll', amount: 481000, dateLabel: 'Oct 01', hasInvoice: true),
    Expense(id: 'E-3', category: ExpenseCategory.utilities, vendor: 'K-Electric', amount: 86400, dateLabel: 'Oct 05', hasInvoice: true),
    Expense(id: 'E-4', category: ExpenseCategory.supplies, vendor: 'Global Spices Co.', amount: 124500, dateLabel: 'Oct 08', hasInvoice: true),
    Expense(id: 'E-5', category: ExpenseCategory.marketing, vendor: 'Meta Ads', amount: 45000, dateLabel: 'Oct 10', hasInvoice: false),
    Expense(id: 'E-6', category: ExpenseCategory.maintenance, vendor: 'CoolTech HVAC', amount: 28000, dateLabel: 'Oct 11', hasInvoice: true),
  ];

  void addExpense({
    required ExpenseCategory category,
    required String vendor,
    required double amount,
    required bool hasInvoice,
  }) {
    state = [
      Expense(
        id: const Uuid().v4(),
        category: category,
        vendor: vendor,
        amount: amount,
        dateLabel: 'Today',
        hasInvoice: hasInvoice,
      ),
      ...state,
    ];
  }

  void updateExpense(
    String id, {
    required ExpenseCategory category,
    required String vendor,
    required double amount,
    required bool hasInvoice,
  }) {
    state = [
      for (final e in state)
        if (e.id == id)
          Expense(
            id: e.id,
            category: category,
            vendor: vendor,
            amount: amount,
            dateLabel: e.dateLabel,
            hasInvoice: hasInvoice,
          )
        else
          e,
    ];
  }

  void removeExpense(String id) =>
      state = state.where((e) => e.id != id).toList();
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
