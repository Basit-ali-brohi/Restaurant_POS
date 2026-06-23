import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../providers/kds_provider.dart';

/// A Kitchen Order Ticket (KOT) card for one station slice of an order.
/// Shows the route (table/channel), order number, an elapsed cooking timer with
/// time-ageing colour, the itemised breakdown with modifier flags, a lifecycle
/// stage badge and the single contextual action: Accept → Start Cooking →
/// Mark Ready.
class KdsTicketCard extends ConsumerWidget {
  const KdsTicketCard({
    super.key,
    required this.tones,
    required this.ticket,
    required this.now,
  });

  final AppTones tones;
  final StationTicket ticket;
  final DateTime now;

  ({Color color, String label}) _agingMeta(TicketAging aging) {
    switch (aging) {
      case TicketAging.fresh:
        return (color: AppColors.success, label: 'ON TIME');
      case TicketAging.warning:
        return (color: AppColors.warning, label: 'RUNNING LATE');
      case TicketAging.critical:
        return (color: AppColors.error, label: 'OVERDUE');
    }
  }

  String _elapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _clockTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(kitchenProvider.select(
        (m) => m[ticket.key] ?? TicketStage.pending));
    final notifier = ref.read(kitchenProvider.notifier);

    final elapsed = now.difference(ticket.createdAt);
    final aging = agingFor(elapsed);
    final meta = _agingMeta(aging);

    // Critical tickets (> 15 min) flash at ~1 Hz, driven by the clock parity.
    final flashing = aging == TicketAging.critical && now.second.isEven;
    final borderColor = flashing ? meta.color : meta.color.withValues(alpha: 0.65);
    final borderWidth = aging == TicketAging.critical ? 2.4 : 1.6;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (aging == TicketAging.critical)
            BoxShadow(
              color: meta.color.withValues(alpha: flashing ? 0.45 : 0.18),
              blurRadius: flashing ? 18 : 8,
              spreadRadius: flashing ? 1 : 0,
            )
          else
            BoxShadow(color: tones.shadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(meta, elapsed, stage),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [for (final item in ticket.items) _itemRow(item)],
            ),
          ),
          _footer(notifier, stage),
        ],
      ),
    );
  }

  // --- Header: route + order no + clock + elapsed timer + stage badge --------
  Widget _header(
      ({Color color, String label}) meta, Duration elapsed, TicketStage stage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        border: Border(bottom: BorderSide(color: tones.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ticket.orderType.icon, size: 16, color: tones.textSecondary),
              const SizedBox(width: 6),
              Text(ticket.routeLabel,
                  style: TextStyle(
                      color: tones.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(width: 8),
              Text('#${ticket.billNumber}',
                  style: TextStyle(
                      color: tones.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              _stageBadge(stage),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 13, color: meta.color),
                    const SizedBox(width: 4),
                    Text(_elapsed(elapsed),
                        style: TextStyle(
                            color: meta.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(meta.label,
                  style: TextStyle(
                      color: meta.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.8)),
              const Spacer(),
              Icon(Icons.schedule, size: 12, color: tones.textMuted),
              const SizedBox(width: 4),
              Text(_clockTime(ticket.createdAt),
                  style: TextStyle(color: tones.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageBadge(TicketStage stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: stage.color.withValues(alpha: 0.5)),
      ),
      child: Text(stage.label.toUpperCase(),
          style: TextStyle(
              color: stage.color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.6)),
    );
  }

  // --- Item row with modifier flags ------------------------------------------
  Widget _itemRow(StationTicketItem item) {
    final line = item.line;
    final flags = <String>[
      if (line.variation != null) line.variation!,
      ...line.modifiers,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tones.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tones.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tones.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('${line.quantity}×',
                style: TextStyle(
                    color: tones.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name,
                    style: TextStyle(
                        color: tones.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final flag in flags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4)),
                          ),
                          child: Text(flag,
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Footer: contextual lifecycle action -----------------------------------
  Widget _footer(KitchenNotifier notifier, TicketStage stage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => notifier.advance(ticket.key),
          icon: Icon(stage.actionIcon, size: 18),
          label: Text(stage.action,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: stage.color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
