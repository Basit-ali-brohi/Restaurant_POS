import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

/// SRS 4.4 — Supplier Relationship Management. Vendor ledger with reliability
/// scoring, lead times, outstanding payables and the live restock feed.
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  static String _money(double v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return 'PKR $b';
  }

  static Color _bandColor(double reliability) {
    if (reliability >= 95) return AppColors.success;
    if (reliability >= 85) return AppColors.info;
    if (reliability >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final suppliers = ref.watch(suppliersProvider);
    final requests = ref.watch(restockRequestsProvider);
    final pending = requests.where((r) => r.status != 'received').length;

    final payable =
        suppliers.fold(0.0, (s, e) => s + e.outstandingBalance);
    final avgRel = suppliers.isEmpty
        ? 0.0
        : suppliers.fold(0.0, (s, e) => s + e.reliability) / suppliers.length;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suppliers & SRM',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Vendor ledger, reliability scoring and restock feed.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _SupplierFormSheet.show(context, ref),
                  icon: const Icon(Icons.add_business, size: 18),
                  label: const Text('Add Supplier',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Suppliers', '${suppliers.length}',
                  Icons.local_shipping_outlined, AppColors.info),
              _kpi(t, 'Avg Reliability', '${avgRel.toStringAsFixed(0)}%',
                  Icons.verified_outlined, AppColors.success),
              _kpi(t, 'Total Payable', _money(payable),
                  Icons.account_balance_wallet_outlined, AppColors.warning),
              _kpi(t, 'Open Restocks', '$pending',
                  Icons.pending_actions_outlined, AppColors.accent),
            ]),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 1080;
              final ledger = _ledger(context, t, ref, suppliers);
              final feed = _restockFeed(context, t, ref, requests, suppliers);
              if (stacked) {
                return Column(children: [
                  ledger,
                  const SizedBox(height: 16),
                  feed,
                ]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: ledger),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: feed),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }

  // --- Supplier ledger -------------------------------------------------------
  Widget _ledger(BuildContext context, AppTones t, WidgetRef ref,
      List<SupplierModel> suppliers) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7))),
          child: Row(children: [
            Expanded(flex: 3, child: _h(t, 'SUPPLIER')),
            Expanded(flex: 3, child: _h(t, 'RELIABILITY')),
            SizedBox(width: 64, child: _h(t, 'LEAD')),
            Expanded(flex: 2, child: _h(t, 'PAYABLE')),
            const SizedBox(width: 40),
          ]),
        ),
        if (suppliers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No suppliers',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
          )
        else
          for (int i = 0; i < suppliers.length; i++)
            _supplierRow(
                context, t, ref, suppliers[i], i == suppliers.length - 1),
      ]),
    );
  }

  Widget _supplierRow(BuildContext context, AppTones t, WidgetRef ref,
      SupplierModel s, bool last) {
    final relColor = _bandColor(s.reliability);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.16),
              child: Text(s.name[0],
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  Text('${s.category} · ${s.contact}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('${s.reliability.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: relColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                  const SizedBox(width: 6),
                  Text(s.reliabilityBand,
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.reliability / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: t.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(relColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text('${s.leadDays}d',
              style: TextStyle(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        ),
        Expanded(
          flex: 2,
          child: Text(
              s.outstandingBalance == 0
                  ? 'Settled'
                  : _money(s.outstandingBalance),
              style: TextStyle(
                  color: s.outstandingBalance == 0
                      ? AppColors.success
                      : t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ),
        SizedBox(
          width: 40,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: t.textMuted),
            color: t.surface,
            tooltip: 'Actions',
            onSelected: (v) {
              final n = ref.read(suppliersProvider.notifier);
              switch (v) {
                case 'edit':
                  _SupplierFormSheet.show(context, ref, existing: s);
                case 'settle':
                  n.settleBalance(s.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Settled balance for ${s.name}'),
                    duration: const Duration(milliseconds: 1000),
                    backgroundColor: AppColors.success,
                  ));
                case 'delete':
                  n.removeSupplier(s.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Removed ${s.name}'),
                    duration: const Duration(milliseconds: 1000),
                    backgroundColor: AppColors.error,
                  ));
              }
            },
            itemBuilder: (_) => [
              _menuItem(t, 'edit', Icons.edit_outlined, 'Edit', t.textSecondary),
              if (s.outstandingBalance > 0)
                _menuItem(t, 'settle', Icons.price_check, 'Settle balance',
                    AppColors.success),
              _menuItem(
                  t, 'delete', Icons.delete_outline, 'Delete', AppColors.error),
            ],
          ),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _menuItem(
      AppTones t, String value, IconData icon, String label, Color tint) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(children: [
        Icon(icon, size: 17, color: tint),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: t.textPrimary, fontSize: 13.5)),
      ]),
    );
  }

  // --- Restock feed ----------------------------------------------------------
  Widget _restockFeed(BuildContext context, AppTones t, WidgetRef ref,
      List<RestockRequest> requests, List<SupplierModel> suppliers) {
    String supplierName(String? id) {
      final found = suppliers.where((s) => s.id == id).toList();
      return found.isEmpty ? (id ?? '—') : found.first.name;
    }

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
            child: Row(children: [
              Text('Restock Requests',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.inventory_outlined, size: 18, color: AppColors.accent),
            ]),
          ),
          Divider(height: 1, color: t.border),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text('No restock requests yet',
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
              ),
            )
          else
            for (final r in requests)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.border))),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.itemName,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5)),
                        Text(
                            '${r.quantityLabel} · ${supplierName(r.supplierId)}',
                            style:
                                TextStyle(color: t.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  if (r.status == 'received')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Received',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    )
                  else
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(restockRequestsProvider.notifier)
                              .acceptRequest(r.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Received: ${r.itemName}'),
                              duration: const Duration(milliseconds: 1000),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Accept',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ),
                ]),
              ),
        ],
      ),
    );
  }

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));
}

// =============================================================================
// ADD / EDIT SUPPLIER FORM
// =============================================================================

class _SupplierFormSheet extends ConsumerStatefulWidget {
  const _SupplierFormSheet({this.existing});
  final SupplierModel? existing;

  static const List<String> categories = [
    'Produce',
    'Meat',
    'Seafood',
    'Dairy',
    'Bakery',
    'Dry Goods',
    'Spices',
    'Beverages',
    'General',
  ];

  static Future<void> show(BuildContext context, WidgetRef ref,
          {SupplierModel? existing}) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => _SupplierFormSheet(existing: existing),
      );

  @override
  ConsumerState<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends ConsumerState<_SupplierFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _contact;
  late final TextEditingController _reliability;
  late final TextEditingController _lead;
  late final TextEditingController _balance;
  late String _category;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _contact = TextEditingController(text: s?.contact ?? '');
    _reliability =
        TextEditingController(text: (s?.reliability ?? 95).toStringAsFixed(0));
    _lead = TextEditingController(text: (s?.leadDays ?? 2).toString());
    _balance = TextEditingController(
        text: s == null ? '0' : s.outstandingBalance.round().toString());
    _category = s?.category ?? 'General';
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _reliability.dispose();
    _lead.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final rel = (double.tryParse(_reliability.text.trim()) ?? 95).clamp(0, 100);
    final lead = int.tryParse(_lead.text.trim()) ?? 2;
    final bal = double.tryParse(_balance.text.trim()) ?? 0;
    final n = ref.read(suppliersProvider.notifier);
    if (_isEdit) {
      n.updateSupplier(widget.existing!.copyWith(
        name: name,
        contact: _contact.text.trim(),
        category: _category,
        reliability: rel.toDouble(),
        leadDays: lead,
        outstandingBalance: bal,
      ));
    } else {
      n.addSupplier(SupplierModel(
        id: 'S-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        contact: _contact.text.trim(),
        category: _category,
        reliability: rel.toDouble(),
        leadDays: lead,
        outstandingBalance: bal,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.border))),
                child: Row(children: [
                  Text(_isEdit ? 'Edit Supplier' : 'Add Supplier',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: t.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(t, 'Supplier name', _name, Icons.business_outlined),
                    const SizedBox(height: 12),
                    _field(t, 'Contact', _contact, Icons.phone_outlined),
                    const SizedBox(height: 12),
                    Text('Category',
                        style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _category,
                          dropdownColor: t.surface,
                          icon: Icon(Icons.expand_more, color: t.textMuted),
                          style: TextStyle(color: t.textPrimary, fontSize: 14),
                          items: [
                            for (final c in _SupplierFormSheet.categories)
                              DropdownMenuItem(value: c, child: Text(c)),
                          ],
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _field(t, 'Reliability %', _reliability,
                            Icons.verified_outlined,
                            number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                            t, 'Lead days', _lead, Icons.schedule_outlined,
                            number: true),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _field(t, 'Outstanding balance (PKR)', _balance,
                        Icons.account_balance_wallet_outlined,
                        number: true),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.error_outline,
                            size: 15, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12.5)),
                      ]),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.border))),
                child: Row(children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text('Cancel', style: TextStyle(color: t.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_isEdit ? 'Save Changes' : 'Add Supplier',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(AppTones t, String hint, TextEditingController c, IconData icon,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: TextStyle(color: t.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted),
        prefixIcon: Icon(icon, size: 18, color: t.textMuted),
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
