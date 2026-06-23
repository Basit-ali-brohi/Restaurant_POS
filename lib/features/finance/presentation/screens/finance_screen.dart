import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../providers/finance_provider.dart';

/// SCREENS 63–66 — Finance Center & P&L. Expense ledger with invoice flags,
/// an add-entry form, and a simulated monthly Profit & Loss summary that draws
/// real revenue from the order repository.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final _vendor = TextEditingController();
  final _amount = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.supplies;
  bool _invoice = true;
  String? _editingId;

  @override
  void dispose() {
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  static String _money(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}PKR $b';
  }

  void _submit() {
    final amt = double.tryParse(_amount.text.trim());
    if (_vendor.text.trim().isEmpty || amt == null || amt <= 0) return;
    final n = ref.read(expensesProvider.notifier);
    if (_editingId != null) {
      n.updateExpense(_editingId!,
          category: _category,
          vendor: _vendor.text.trim(),
          amount: amt,
          hasInvoice: _invoice);
    } else {
      n.addExpense(
          category: _category,
          vendor: _vendor.text.trim(),
          amount: amt,
          hasInvoice: _invoice);
    }
    setState(() {
      _vendor.clear();
      _amount.clear();
      _editingId = null;
    });
  }

  void _startEdit(Expense e) {
    setState(() {
      _editingId = e.id;
      _vendor.text = e.vendor;
      _amount.text = e.amount.round().toString();
      _category = e.category;
      _invoice = e.hasInvoice;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _vendor.clear();
      _amount.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final expenses = ref.watch(expensesProvider);
    final byCat = ref.watch(expensesByCategoryProvider);

    // Live revenue from committed orders (scaled to a monthly figure for demo).
    final liveRevenue =
        ref.watch(orderRepositoryProvider).fold(0.0, (s, o) => s + o.breakdown.grandTotal);
    final revenue = 3_240_000 + liveRevenue; // base monthly + live
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    final cogs = revenue * 0.32;
    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - totalExpenses;
    final margin = revenue == 0 ? 0.0 : netProfit / revenue;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance Center',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Expense ledger and Profit & Loss reporting.',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Revenue', _money(revenue), Icons.trending_up,
                  AppColors.success),
              _kpi(t, 'Expenses', _money(totalExpenses),
                  Icons.receipt_long_outlined, AppColors.error),
              _kpi(t, 'Net Profit', _money(netProfit),
                  Icons.account_balance_wallet_outlined, AppColors.accent),
              _kpi(t, 'Net Margin', '${(margin * 100).toStringAsFixed(1)}%',
                  Icons.percent, AppColors.info),
            ]),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 1040;
              final left = Column(children: [
                _addForm(t),
                const SizedBox(height: 16),
                _ledger(t, expenses),
              ]);
              final right = _pnl(
                  t, revenue, cogs, grossProfit, byCat, totalExpenses, netProfit);
              if (stacked) {
                return Column(children: [left, const SizedBox(height: 16), right]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: right),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon, Color tint) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _addForm(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_editingId == null ? 'Record Expense' : 'Edit Expense',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const Spacer(),
            if (_editingId != null)
              GestureDetector(
                onTap: _cancelEdit,
                child: Text('Cancel',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 3,
              child: _input(t, _vendor, 'Vendor / payee'),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _input(t, _amount, 'Amount', number: true),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExpenseCategory>(
                    isExpanded: true,
                    value: _category,
                    dropdownColor: t.surface,
                    icon: Icon(Icons.expand_more, color: t.textMuted),
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5),
                    items: [
                      for (final c in ExpenseCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _invoice = !_invoice),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _invoice
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : t.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _invoice ? AppColors.accent : t.border),
                ),
                child: Row(children: [
                  Icon(_invoice ? Icons.attach_file : Icons.upload_file,
                      size: 16,
                      color: _invoice ? AppColors.accent : t.textMuted),
                  const SizedBox(width: 6),
                  Text('Invoice',
                      style: TextStyle(
                          color: _invoice ? AppColors.accent : t.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_editingId == null ? 'Add' : 'Update',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _ledger(AppTones t, List<Expense> expenses) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text('Expense Ledger',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          Divider(height: 1, color: t.border),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No expenses recorded',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
            )
          else
            for (int i = 0; i < expenses.length; i++)
              _ledgerRow(t, expenses[i], i == expenses.length - 1),
        ],
      ),
    );
  }

  Widget _ledgerRow(AppTones t, Expense e, bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: e.category.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.vendor,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              Text('${e.category.label} · ${e.dateLabel}',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        if (e.hasInvoice)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.receipt, size: 15, color: AppColors.success),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.warning_amber_rounded,
                size: 15, color: AppColors.warning),
          ),
        Text(_money(e.amount),
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13.5)),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 17, color: t.textMuted),
          color: t.surface,
          tooltip: 'Actions',
          onSelected: (v) {
            if (v == 'edit') {
              _startEdit(e);
            } else if (v == 'delete') {
              ref.read(expensesProvider.notifier).removeExpense(e.id);
              if (_editingId == e.id) _cancelEdit();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'edit',
              height: 40,
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 17, color: t.textSecondary),
                const SizedBox(width: 10),
                Text('Edit',
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5)),
              ]),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              height: 40,
              child: Row(children: [
                const Icon(Icons.delete_outline,
                    size: 17, color: AppColors.error),
                const SizedBox(width: 10),
                Text('Delete',
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _pnl(
      AppTones t,
      double revenue,
      double cogs,
      double grossProfit,
      Map<ExpenseCategory, double> byCat,
      double totalExpenses,
      double netProfit) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Row(children: [
              Text('Profit & Loss',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              Text('This Month',
                  style: TextStyle(color: t.textMuted, fontSize: 12)),
            ]),
          ),
          Divider(height: 1, color: t.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(children: [
              _pnlRow(t, 'Revenue', revenue, bold: true),
              _pnlRow(t, 'Cost of Goods Sold (32%)', -cogs),
              Divider(height: 16, color: t.border),
              _pnlRow(t, 'Gross Profit', grossProfit, bold: true, color: AppColors.success),
              const SizedBox(height: 8),
              Text('OPERATING EXPENSES',
                  style: TextStyle(
                      color: t.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 6),
              for (final entry in byCat.entries)
                if (entry.value > 0) _pnlRow(t, entry.key.label, -entry.value),
              Divider(height: 16, color: t.border),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: (netProfit >= 0 ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Text('NET PROFIT',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const Spacer(),
                  Text(_money(netProfit),
                      style: TextStyle(
                          color: netProfit >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _pnlRow(AppTones t, String label, double value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: bold ? t.textPrimary : t.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13)),
        const Spacer(),
        Text(_money(value),
            style: TextStyle(
                color: color ?? (value < 0 ? t.textSecondary : t.textPrimary),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13)),
      ]),
    );
  }

  Widget _input(AppTones t, TextEditingController c, String hint,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      inputFormatters:
          number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
      style: TextStyle(color: t.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
