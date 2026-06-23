import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/delivery_provider.dart';

/// SCREENS 49–52 — Delivery Management Hub. Fleet tracking with active riders,
/// mock coordinate trip progress and a per-rider commission ledger.
class DeliveryHubScreen extends ConsumerWidget {
  const DeliveryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final riders = ref.watch(ridersProvider);
    final active = riders.where((r) => r.onTrip).length;
    final commission = riders.fold(0.0, (s, r) => s + r.commission);
    final delivered = riders.fold(0, (s, r) => s + r.completedToday);

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Hub',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Fleet tracking, trip progress and rider commission ledgers.',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _kpi(t, 'Active Riders', '$active / ${riders.length}',
                  Icons.two_wheeler, AppColors.info),
              _kpi(t, 'Delivered Today', '$delivered',
                  Icons.check_circle_outline, AppColors.success),
              _kpi(t, 'Commission Payable', 'PKR ${commission.toStringAsFixed(0)}',
                  Icons.payments_outlined, AppColors.accent),
            ]),
            const SizedBox(height: 22),
            Text('FLEET',
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 720 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [for (final r in riders) _riderCard(t, r, w)],
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: t.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _riderCard(AppTones t, Rider r, double w) {
    return Container(
      width: w,
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
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accent.withValues(alpha: 0.18),
              child: Text(r.name[0],
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
                  Text(r.zone,
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: (r.onTrip ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(r.onTrip ? 'On Trip' : 'Idle',
                  style: TextStyle(
                      color: r.onTrip ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5)),
            ),
          ]),
          const SizedBox(height: 14),
          // Mock coordinate progress.
          Row(children: [
            Text('Trip', style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            const Spacer(),
            Text('${(r.progress * 100).round()}%',
                style: TextStyle(
                    color: t.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.onTrip ? r.progress : (r.progress == 0 ? 0.0 : 1.0),
              minHeight: 7,
              backgroundColor: t.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(
                  r.onTrip ? AppColors.accent : AppColors.success),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.restaurant, size: 12, color: t.textMuted),
            const SizedBox(width: 4),
            Text('Restaurant',
                style: TextStyle(color: t.textMuted, fontSize: 10)),
            const Spacer(),
            Text('Customer',
                style: TextStyle(color: t.textMuted, fontSize: 10)),
            const SizedBox(width: 4),
            Icon(Icons.location_on, size: 12, color: t.textMuted),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: t.border),
          const SizedBox(height: 12),
          Row(children: [
            _stat(t, 'Active', '${r.activeTrips}'),
            _stat(t, 'Done Today', '${r.completedToday}'),
            _stat(t, 'Commission', 'PKR ${r.commission.toStringAsFixed(0)}',
                accent: true),
          ]),
        ],
      ),
    );
  }

  Widget _stat(AppTones t, String label, String value, {bool accent = false}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: accent ? AppColors.accent : t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        Text(label, style: TextStyle(color: t.textMuted, fontSize: 10.5)),
      ]),
    );
  }
}
