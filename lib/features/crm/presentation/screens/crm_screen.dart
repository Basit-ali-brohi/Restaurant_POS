import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/crm_provider.dart';

/// SCREENS 43–46 — CRM & Loyalty Engine. Customer segment profiles, lifetime
/// fidelity points, loyalty tiers (Silver/Gold/…) and marketing campaigns.
class CrmScreen extends ConsumerWidget {
  const CrmScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final all = ref.watch(customersProvider);
    final filter = ref.watch(crmSegmentFilterProvider);
    final customers =
        filter == null ? all : all.where((c) => c.segment == filter).toList();

    final totalPoints = all.fold(0, (s, c) => s + c.points);
    final goldPlus = all
        .where((c) =>
            c.tier == LoyaltyTier.gold || c.tier == LoyaltyTier.platinum)
        .length;
    final atRisk =
        all.where((c) => c.segment == CustomerSegment.atRisk).length;

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
                  Text('CRM & Loyalty',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text(
                      'Customer profiles, fidelity points and marketing campaigns.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _CustomerFormSheet.show(context, ref),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('New Member',
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
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 3 * 16) / 4;
              final cardW = w < 200 ? c.maxWidth : w;
              return Wrap(spacing: 16, runSpacing: 16, children: [
                _kpi(t, 'Members', '${all.length}', Icons.groups_outlined,
                    AppColors.info, cardW),
                _kpi(t, 'Points Issued', '$totalPoints',
                    Icons.stars_outlined, AppColors.accent, cardW),
                _kpi(t, 'Gold+ Members', '$goldPlus',
                    Icons.workspace_premium_outlined,
                    const Color(0xFFE3B041), cardW),
                _kpi(t, 'At-Risk', '$atRisk', Icons.warning_amber_rounded,
                    AppColors.error, cardW),
              ]);
            }),
            const SizedBox(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _chip(ref, t, null, 'All Segments', filter == null),
              for (final s in CustomerSegment.values)
                _chip(ref, t, s, s.label, filter == s),
            ]),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 1040;
              final table = _customerTable(context, t, ref, customers);
              final camps = _campaigns(t, ref);
              if (stacked) {
                return Column(children: [
                  table,
                  const SizedBox(height: 16),
                  camps
                ]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: table),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: camps),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _kpi(AppTones t, String label, String value, IconData icon,
      Color tint, double w) {
    return Container(
      width: w,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 14, offset: const Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 19, color: tint),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: TextStyle(
                color: t.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: t.textMuted, fontSize: 12.5)),
      ]),
    );
  }

  Widget _chip(WidgetRef ref, AppTones t, CustomerSegment? seg, String label,
      bool selected) {
    return GestureDetector(
      onTap: () => ref.read(crmSegmentFilterProvider.notifier).state = seg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accent : t.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : t.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }

  Widget _customerTable(
      BuildContext context, AppTones t, WidgetRef ref, List<Customer> rows) {
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
            Expanded(flex: 3, child: _h(t, 'CUSTOMER')),
            Expanded(flex: 2, child: _h(t, 'TIER')),
            Expanded(flex: 2, child: _h(t, 'POINTS')),
            Expanded(flex: 2, child: _h(t, 'LIFETIME')),
            SizedBox(width: 90, child: _h(t, 'SEGMENT')),
            const SizedBox(width: 40),
          ]),
        ),
        for (int i = 0; i < rows.length; i++)
          _row(context, t, ref, rows[i], i == rows.length - 1),
      ]),
    );
  }

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));

  Widget _row(BuildContext context, AppTones t, WidgetRef ref, Customer c,
      bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          border:
              last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: c.tier.color.withValues(alpha: 0.2),
              child: Text(c.name[0],
                  style: TextStyle(
                      color: c.tier.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  Text(c.phone,
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            Icon(Icons.workspace_premium, size: 14, color: c.tier.color),
            const SizedBox(width: 5),
            Text(c.tier.label,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text('${c.points}',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5)),
        ),
        Expanded(
          flex: 2,
          child: Text(_money(c.lifetimeSpend),
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
        ),
        SizedBox(
          width: 90,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: c.segment.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(c.segment.label,
                  style: TextStyle(
                      color: c.segment.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5)),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: t.textMuted),
            color: t.surface,
            tooltip: 'Actions',
            onSelected: (v) {
              final n = ref.read(customersProvider.notifier);
              switch (v) {
                case 'points':
                  n.addPoints(c.id, 100);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('+100 points to ${c.name}'),
                    duration: const Duration(milliseconds: 900),
                    backgroundColor: AppColors.success,
                  ));
                case 'edit':
                  _CustomerFormSheet.show(context, ref, existing: c);
                case 'delete':
                  n.remove(c.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Removed ${c.name}'),
                    duration: const Duration(milliseconds: 900),
                    backgroundColor: AppColors.error,
                  ));
              }
            },
            itemBuilder: (_) => [
              _menuItem(t, 'points', Icons.add_circle_outline,
                  'Add 100 points', AppColors.accent),
              _menuItem(t, 'edit', Icons.edit_outlined, 'Edit profile',
                  t.textSecondary),
              _menuItem(
                  t, 'delete', Icons.delete_outline, 'Delete', AppColors.error),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _campaigns(AppTones t, WidgetRef ref) {
    final camps = ref.watch(campaignsProvider);
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
              Text('Marketing Campaigns',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.campaign_outlined, size: 18, color: AppColors.accent),
            ]),
          ),
          Divider(height: 1, color: t.border),
          for (final m in camps) _campaignRow(t, m),
        ],
      ),
    );
  }

  Widget _campaignRow(AppTones t, MarketingCampaign m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: m.active ? AppColors.success : t.textMuted,
              shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              Text('${m.channel} · ${m.audience} · ${m.reward}',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: (m.active ? AppColors.success : t.textMuted)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6)),
          child: Text(m.active ? 'Active' : 'Paused',
              style: TextStyle(
                  color: m.active ? AppColors.success : t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5)),
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
}

// =============================================================================
// CUSTOMER CREATE / EDIT FORM
// =============================================================================

class _CustomerFormSheet extends ConsumerStatefulWidget {
  const _CustomerFormSheet({this.existing});
  final Customer? existing;

  static Future<void> show(BuildContext context, WidgetRef ref,
          {Customer? existing}) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => _CustomerFormSheet(existing: existing),
      );

  @override
  ConsumerState<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<_CustomerFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late CustomerSegment _segment;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _segment = c?.segment ?? CustomerSegment.newcomer;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final n = ref.read(customersProvider.notifier);
    if (_isEdit) {
      n.update(widget.existing!.id,
          name: name,
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          segment: _segment);
    } else {
      n.add(name: name, phone: _phone.text.trim(), email: _email.text.trim());
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
        constraints: const BoxConstraints(maxWidth: 460),
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
                  Text(_isEdit ? 'Edit Member' : 'New Member',
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
                    _field(t, 'Full name', _name, Icons.person_outline),
                    const SizedBox(height: 12),
                    _field(t, 'Phone', _phone, Icons.phone_outlined),
                    const SizedBox(height: 12),
                    _field(t, 'Email', _email, Icons.mail_outline),
                    if (_isEdit) ...[
                      const SizedBox(height: 14),
                      Text('Segment',
                          style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final s in CustomerSegment.values)
                          GestureDetector(
                            onTap: () => setState(() => _segment = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _segment == s
                                    ? s.color.withValues(alpha: 0.16)
                                    : t.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _segment == s ? s.color : t.border),
                              ),
                              child: Text(s.label,
                                  style: TextStyle(
                                      color: _segment == s
                                          ? s.color
                                          : t.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ),
                          ),
                      ]),
                    ],
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
                    child: Text('Cancel',
                        style: TextStyle(color: t.textMuted)),
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
                      child: Text(_isEdit ? 'Save Changes' : 'Add Member',
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

  Widget _field(AppTones t, String hint, TextEditingController c,
      IconData icon) {
    return TextField(
      controller: c,
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
