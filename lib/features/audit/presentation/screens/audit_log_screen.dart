import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/audit_provider.dart';

/// SCREENS 77–82 — Reporting Dashboard & Forensic Audit Log. A unified,
/// chronological and immutable record of every system state mutation, with
/// category reporting summaries and filtering.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final filter = ref.watch(auditFilterProvider);
    final all = ref.watch(auditLogProvider);
    final counts = ref.watch(auditCountsProvider);
    final entries =
        filter == null ? all : all.where((e) => e.category == filter).toList();

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
                  Text('Forensic Audit Log',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Immutable, chronological record of all system mutations.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline, size: 14, color: t.textMuted),
                  const SizedBox(width: 6),
                  Text('${all.length} immutable events',
                      style: TextStyle(
                          color: t.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            // Reporting summary.
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 4 * 14) / 5;
              final cardW = w < 150 ? (c.maxWidth - 14) / 2 : w;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                for (final cat in AuditCategory.values)
                  _summary(t, cat, counts[cat] ?? 0, cardW),
              ]);
            }),
            const SizedBox(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _chip(ref, t, null, 'All', filter == null),
              for (final cat in AuditCategory.values)
                _chip(ref, t, cat, cat.label, filter == cat),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(children: [
                for (int i = 0; i < entries.length; i++)
                  _entryRow(t, entries[i], i == entries.length - 1),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(AppTones t, AuditCategory cat, int count, double w) {
    return Container(
      width: w,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(cat.icon, size: 18, color: cat.color),
        const SizedBox(height: 10),
        Text('$count',
            style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        Text(cat.label, style: TextStyle(color: t.textMuted, fontSize: 11.5)),
      ]),
    );
  }

  Widget _chip(WidgetRef ref, AppTones t, AuditCategory? cat, String label,
      bool selected) {
    return GestureDetector(
      onTap: () => ref.read(auditFilterProvider.notifier).state = cat,
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

  Widget _entryRow(AppTones t, AuditEntry e, bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: e.category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(e.category.icon, size: 16, color: e.category.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(e.action,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: e.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(e.category.label,
                    style: TextStyle(
                        color: e.category.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(e.detail,
                style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
          ]),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(e.actor,
              style: TextStyle(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          Text(_stamp(e.at),
              style: TextStyle(color: t.textMuted, fontSize: 10.5)),
        ]),
      ]),
    );
  }
}
