import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../table_management/domain/models/table_model.dart';
import '../../../table_management/presentation/providers/table_provider.dart';
import '../providers/reservations_provider.dart';

/// SCREENS 17–18 — Reservations Matrix. A registry form (left) feeding a live,
/// time-sorted reservations list (right) with per-row status transitions.
class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() =>
      _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _party = 2;
  DateTime? _when;
  String? _tableName;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  static String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Guest name is required');
      return;
    }
    if (_when == null) {
      setState(() => _error = 'Pick a date & time');
      return;
    }
    ref.read(reservationsProvider.notifier).add(
          guestName: _name.text.trim(),
          phone: _phone.text.trim(),
          partySize: _party,
          time: _when!,
          tableName: _tableName,
        );
    setState(() {
      _name.clear();
      _phone.clear();
      _party = 2;
      _when = null;
      _tableName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));

    return Container(
      color: t.canvas,
      child: LayoutBuilder(builder: (context, c) {
        final stacked = c.maxWidth < 920;
        final form = _form(t);
        final list = _matrix(t);
        if (stacked) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [form, const SizedBox(height: 16), list]),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: form),
              const SizedBox(width: 16),
              Expanded(child: list),
            ],
          ),
        );
      }),
    );
  }

  // --- Registry form ---------------------------------------------------------
  Widget _form(AppTones t) {
    final available = ref
        .watch(tableProvider)
        .where((tb) => tb.status == TableStatus.available)
        .map((tb) => tb.name)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Reservation',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _label(t, 'Guest name'),
          _input(t, _name, 'e.g. Ayesha Khan'),
          const SizedBox(height: 12),
          _label(t, 'Phone'),
          _input(t, _phone, '+92 3xx xxxxxxx',
              keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _label(t, 'Party size'),
          Row(
            children: [
              _stepBtn(t, Icons.remove,
                  () => setState(() => _party = (_party - 1).clamp(1, 30))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('$_party',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              _stepBtn(t, Icons.add,
                  () => setState(() => _party = (_party + 1).clamp(1, 30))),
              const Spacer(),
              Icon(Icons.groups, color: t.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _label(t, 'Date & time'),
          GestureDetector(
            onTap: _pickWhen,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 18, color: t.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    _when == null
                        ? 'Pick date & time'
                        : '${_fmtDate(_when!)} · ${_fmtTime(_when!)}',
                    style: TextStyle(
                        color: _when == null ? t.textMuted : t.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label(t, 'Assign table (optional)'),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _tableName,
                dropdownColor: t.surface,
                hint: Text('No table',
                    style: TextStyle(color: t.textMuted, fontSize: 14)),
                icon: Icon(Icons.expand_more, color: t.textMuted),
                style: TextStyle(color: t.textPrimary, fontSize: 14),
                items: [
                  DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No table',
                          style: TextStyle(color: t.textMuted))),
                  for (final name in available)
                    DropdownMenuItem<String?>(
                        value: name, child: Text(name)),
                ],
                onChanged: (v) => setState(() => _tableName = v),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 15, color: AppColors.error),
                const SizedBox(width: 6),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12.5)),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Reservation',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
    );
  }

  // --- Reservations matrix ---------------------------------------------------
  Widget _matrix(AppTones t) {
    final reservations = ref.watch(sortedReservationsProvider);
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
            child: Row(
              children: [
                Text('Reservations',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${reservations.length} today',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          _matrixHeader(t),
          Divider(height: 1, color: t.border),
          if (reservations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('No reservations yet',
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
              ),
            )
          else
            for (final r in reservations) _matrixRow(t, r),
        ],
      ),
    );
  }

  Widget _matrixHeader(AppTones t) {
    TextStyle s() => TextStyle(
        color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('GUEST', style: s())),
          Expanded(flex: 2, child: Text('TIME', style: s())),
          SizedBox(width: 60, child: Text('PARTY', style: s())),
          SizedBox(width: 70, child: Text('TABLE', style: s())),
          SizedBox(width: 110, child: Text('STATUS', style: s())),
          const SizedBox(width: 150),
        ],
      ),
    );
  }

  Widget _matrixRow(AppTones t, Reservation r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.guestName,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
                if (r.phone.isNotEmpty)
                  Text(r.phone,
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtTime(r.time),
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          SizedBox(
            width: 60,
            child: Text('${r.partySize}',
                style: TextStyle(color: t.textSecondary, fontSize: 13)),
          ),
          SizedBox(
            width: 70,
            child: r.tableName == null
                ? Text('—', style: TextStyle(color: t.textMuted))
                : Text(r.tableName!,
                    style: TextStyle(
                        color: t.textPrimary, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: r.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.status.label,
                    style: TextStyle(
                        color: r.status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5)),
              ),
            ),
          ),
          SizedBox(width: 150, child: _rowActions(t, r)),
        ],
      ),
    );
  }

  Widget _rowActions(AppTones t, Reservation r) {
    final notifier = ref.read(reservationsProvider.notifier);
    Widget btn(String label, Color color, VoidCallback onTap) => GestureDetector(
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

    switch (r.status) {
      case ReservationStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            btn('Cancel', AppColors.error,
                () => notifier.setStatus(r.id, ReservationStatus.cancelled)),
            const SizedBox(width: 8),
            btn('Confirm', AppColors.info,
                () => notifier.setStatus(r.id, ReservationStatus.confirmed)),
          ],
        );
      case ReservationStatus.confirmed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            btn('Cancel', AppColors.error,
                () => notifier.setStatus(r.id, ReservationStatus.cancelled)),
            const SizedBox(width: 8),
            btn('Seat', AppColors.success,
                () => notifier.setStatus(r.id, ReservationStatus.seated)),
          ],
        );
      case ReservationStatus.seated:
        return Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.check_circle, size: 18, color: AppColors.success),
        );
      case ReservationStatus.cancelled:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            btn('Delete', AppColors.error, () => notifier.remove(r.id)),
          ],
        );
    }
  }

  // --- Small helpers ---------------------------------------------------------
  Widget _label(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _input(AppTones t, TextEditingController c, String hint,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: TextStyle(color: t.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _stepBtn(AppTones t, IconData icon, VoidCallback onTap) {
    return Material(
      color: t.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, size: 18, color: t.textPrimary),
        ),
      ),
    );
  }
}
