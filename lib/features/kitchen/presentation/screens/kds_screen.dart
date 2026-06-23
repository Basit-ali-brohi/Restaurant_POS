import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../providers/kds_provider.dart';
import '../widgets/kds_ticket_card.dart';

// =============================================================================
// KITCHEN DISPLAY SYSTEM — live, station-routed order board
// Reads the shared order repository, splits each order into per-station KOT
// tickets and ages them by elapsed cooking time.
// =============================================================================

class KDSScreen extends ConsumerWidget {
  const KDSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final ticketsByStation = ref.watch(stationTicketsProvider);
    final activeCount = ref.watch(activeTicketCountProvider);

    return Container(
      color: t.canvas,
      child: Column(
        children: [
          _header(t, activeCount),
          Divider(height: 1, color: t.border),
          Expanded(
            child: activeCount == 0
                ? _allClear(t)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final station in KitchenStation.values)
                          _StationColumn(
                            tones: t,
                            station: station,
                            tickets: ticketsByStation[station] ?? const [],
                            now: now,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppTones t, int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text('Kitchen Display System',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text('$activeCount active',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const Spacer(),
          _agingLegend(t),
        ],
      ),
    );
  }

  Widget _agingLegend(AppTones t) {
    Widget chip(Color c, String label) => Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ],
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(AppColors.success, '< 10 min'),
        chip(AppColors.warning, '10–15 min'),
        chip(AppColors.error, '> 15 min'),
      ],
    );
  }

  Widget _allClear(AppTones t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.done_all, size: 52, color: AppColors.success),
          const SizedBox(height: 14),
          Text('All caught up',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('No active kitchen tickets — new orders appear here instantly',
              style: TextStyle(color: t.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StationColumn extends StatelessWidget {
  const _StationColumn({
    required this.tones,
    required this.station,
    required this.tickets,
    required this.now,
  });

  final AppTones tones;
  final KitchenStation station;
  final List<StationTicket> tickets;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: tones.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Column(
        children: [
          // Station header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tones.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(bottom: BorderSide(color: tones.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(station.icon, size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(station.label,
                      style: TextStyle(
                          color: tones.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tickets.isEmpty
                        ? tones.surfaceAlt
                        : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${tickets.length}',
                      style: TextStyle(
                          color: tickets.isEmpty
                              ? tones.textMuted
                              : Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          // Tickets — fills the remaining column height and scrolls.
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 30, color: tones.textMuted),
                        const SizedBox(height: 8),
                        Text('No tickets',
                            style: TextStyle(
                                color: tones.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final ticket in tickets)
                        KdsTicketCard(
                          tones: tones,
                          ticket: ticket,
                          now: now,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
