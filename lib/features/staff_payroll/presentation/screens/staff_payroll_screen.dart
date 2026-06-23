import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../../core/pdf/pdf_view.dart';
import '../providers/payroll_provider.dart';

/// SCREENS 53–59 — Staff & Payroll. Workforce roster with live check-in/out,
/// salary sheets (basic + allowances − deductions) and a printable payslip card.
class StaffPayrollScreen extends ConsumerStatefulWidget {
  const StaffPayrollScreen({super.key});

  @override
  ConsumerState<StaffPayrollScreen> createState() =>
      _StaffPayrollScreenState();
}

class _StaffPayrollScreenState extends ConsumerState<StaffPayrollScreen> {
  String? _selectedId;

  static String _money(double v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return 'PKR $b';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final staff = ref.watch(payrollProvider);
    final selected = staff.firstWhere((e) => e.id == _selectedId,
        orElse: () => staff.first);

    final clockedIn =
        staff.where((e) => e.status == StaffStatus.clockedIn).length;
    final totalHours = staff.fold(0.0, (s, e) => s + e.weeklyHours);
    final payroll = staff.fold(0.0, (s, e) => s + e.netPay);

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
                  Text('Staff & Payroll',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Check-in/out logs, salary sheets and payslips.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _StaffFormSheet.show(context, ref),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Hire Staff',
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
              _kpi(t, 'Active Staff', '${staff.length}', Icons.groups_outlined,
                  AppColors.info),
              _kpi(t, 'Clocked In', '$clockedIn', Icons.timer_outlined,
                  AppColors.success),
              _kpi(t, 'Total Hours (wk)', totalHours.toStringAsFixed(0),
                  Icons.schedule, AppColors.accent),
              _kpi(t, 'Monthly Payroll', _money(payroll),
                  Icons.payments_outlined, AppColors.warning),
            ]),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 1000;
              final table = _roster(t, staff);
              final payslip = _payslip(t, selected);
              if (stacked) {
                return Column(children: [
                  table,
                  const SizedBox(height: 16),
                  payslip
                ]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: table),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: payslip),
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

  Widget _roster(AppTones t, List<Employee> staff) {
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
            Expanded(flex: 3, child: _h(t, 'STAFF MEMBER')),
            Expanded(flex: 2, child: _h(t, 'ROLE')),
            Expanded(flex: 2, child: _h(t, 'STATUS')),
            SizedBox(width: 70, child: _h(t, 'WK HRS')),
            const SizedBox(width: 168, child: SizedBox()),
          ]),
        ),
        for (int i = 0; i < staff.length; i++)
          _row(t, staff[i], i == staff.length - 1),
      ]),
    );
  }

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));

  Widget _row(AppTones t, Employee e, bool last) {
    final selected = _selectedId == e.id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.06) : null,
        border: last ? null : Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.18),
              child: Text(e.initials,
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  Text('ID: ${e.id}',
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(e.role,
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: e.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: e.status.color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(e.status.label,
                    style: TextStyle(
                        color: e.status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ]),
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(e.weeklyHours.toStringAsFixed(1),
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        SizedBox(
          width: 168,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _miniBtn(t, e.status == StaffStatus.clockedIn ? 'Out' : 'In',
                e.status == StaffStatus.clockedIn ? AppColors.error : AppColors.success,
                () => ref.read(payrollProvider.notifier).setStatus(
                    e.id,
                    e.status == StaffStatus.clockedIn
                        ? StaffStatus.offDuty
                        : StaffStatus.clockedIn)),
            const SizedBox(width: 6),
            _miniBtn(t, 'View', AppColors.accent,
                () => setState(() => _selectedId = e.id)),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: t.textMuted),
              color: t.surface,
              padding: EdgeInsets.zero,
              tooltip: 'Actions',
              onSelected: (v) {
                final n = ref.read(payrollProvider.notifier);
                if (v == 'edit') {
                  _StaffFormSheet.show(context, ref, existing: e);
                } else if (v == 'delete') {
                  n.remove(e.id);
                  if (_selectedId == e.id) setState(() => _selectedId = null);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Removed ${e.name}'),
                    duration: const Duration(milliseconds: 900),
                    backgroundColor: AppColors.error,
                  ));
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
                        style:
                            TextStyle(color: t.textPrimary, fontSize: 13.5)),
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
                        style:
                            TextStyle(color: t.textPrimary, fontSize: 13.5)),
                  ]),
                ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _miniBtn(AppTones t, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );
  }

  // --- Payslip card ----------------------------------------------------------
  Widget _payslip(AppTones t, Employee e) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Text(e.initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('${e.role} · ${e.id}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12)),
                  ],
                ),
              ),
              const Text('PAYSLIP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _payRow(t, 'Basic Salary', e.basicSalary, false),
                _payRow(t, 'Allowances', e.allowances, false),
                const SizedBox(height: 6),
                Divider(height: 1, color: t.border),
                const SizedBox(height: 6),
                for (final d in e.deductions)
                  _payRow(t, d.label, -d.amount, true),
                const SizedBox(height: 6),
                Divider(height: 1, color: t.border),
                const SizedBox(height: 10),
                Row(children: [
                  Text('NET PAY',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const Spacer(),
                  Text(_money(e.netPay),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => PdfViewer.show(
                      context,
                      title: 'Payslip — ${e.name}',
                      fileName: 'payslip_${e.id}.pdf',
                      build: (format) => PdfService.buildPayslip(e),
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('View / Download Payslip',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRow(AppTones t, String label, double value, bool deduction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: TextStyle(color: t.textSecondary, fontSize: 13)),
        const Spacer(),
        Text('${deduction ? '-' : ''}${_money(value.abs())}',
            style: TextStyle(
                color: deduction ? AppColors.error : t.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    );
  }
}

// =============================================================================
// HIRE / EDIT STAFF FORM
// =============================================================================

class _StaffFormSheet extends ConsumerStatefulWidget {
  const _StaffFormSheet({this.existing});
  final Employee? existing;

  static Future<void> show(BuildContext context, WidgetRef ref,
          {Employee? existing}) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => _StaffFormSheet(existing: existing),
      );

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _salary;
  late final TextEditingController _allowance;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _cnic;
  late final TextEditingController _joinDate;
  late String _role;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _salary =
        TextEditingController(text: e == null ? '' : e.basicSalary.round().toString());
    _allowance =
        TextEditingController(text: e == null ? '' : e.allowances.round().toString());
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _cnic = TextEditingController(text: e?.cnic ?? '');
    _joinDate = TextEditingController(text: e?.joinDate ?? '');
    _role = e?.role ?? PayrollNotifier.roles.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _salary.dispose();
    _allowance.dispose();
    _email.dispose();
    _phone.dispose();
    _cnic.dispose();
    _joinDate.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final salary = double.tryParse(_salary.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    if (salary == null || salary <= 0) {
      setState(() => _error = 'Enter a valid basic salary');
      return;
    }
    final allowance = double.tryParse(_allowance.text.trim()) ?? 0;
    final n = ref.read(payrollProvider.notifier);
    if (_isEdit) {
      n.update(widget.existing!.id,
          name: name,
          role: _role,
          basicSalary: salary,
          allowances: allowance,
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          cnic: _cnic.text.trim(),
          joinDate: _joinDate.text.trim());
    } else {
      n.add(
          name: name,
          role: _role,
          basicSalary: salary,
          allowances: allowance,
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          cnic: _cnic.text.trim(),
          joinDate: _joinDate.text.trim());
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
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 660),
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
                  Text(_isEdit ? 'Edit Staff' : 'Hire Staff',
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
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(t, 'Full name', _name, Icons.person_outline),
                    const SizedBox(height: 12),
                    Text('Role',
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
                          value: _role,
                          dropdownColor: t.surface,
                          icon: Icon(Icons.expand_more, color: t.textMuted),
                          style:
                              TextStyle(color: t.textPrimary, fontSize: 14),
                          items: [
                            for (final r in PayrollNotifier.roles)
                              DropdownMenuItem(value: r, child: Text(r)),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _field(t, 'Basic salary', _salary,
                            Icons.payments_outlined,
                            number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(t, 'Allowances', _allowance,
                            Icons.add_card_outlined,
                            number: true),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _field(
                              t, 'Email', _email, Icons.mail_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(
                              t, 'Phone', _phone, Icons.phone_outlined)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _field(t, 'CNIC', _cnic,
                              Icons.badge_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(t, 'Join date', _joinDate,
                              Icons.event_outlined)),
                    ]),
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
                      child: Text(_isEdit ? 'Save Changes' : 'Add Employee',
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
