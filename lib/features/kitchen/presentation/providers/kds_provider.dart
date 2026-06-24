import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../pos/domain/models/pos_models.dart';
import '../../../pos/presentation/providers/pos_providers.dart';

// =============================================================================
// KDS STATE LAYER
// Routes committed orders into per-station kitchen tickets and overlays the
// mutable kitchen lifecycle (Accept -> Start Cooking -> Mark Ready) on top of
// the immutable shared order repository.
// =============================================================================

/// Distinct kitchen stations. Each serves a set of menu categories; smart
/// routing splits an order so a station only sees the items it must cook.
enum KitchenStation {
  grill('Grill Station', Icons.outdoor_grill, ['Mains']),
  mainKitchen('Main Kitchen', Icons.soup_kitchen, ['Starters', 'Sides', 'Desserts']),
  beverage('Beverage', Icons.local_bar, ['Drinks']);

  const KitchenStation(this.label, this.icon, this.categories);
  final String label;
  final IconData icon;
  final List<String> categories;

  /// Station responsible for a menu category (Main Kitchen is the catch-all).
  static KitchenStation forCategory(String category) {
    for (final station in KitchenStation.values) {
      if (station.categories.contains(category)) return station;
    }
    return KitchenStation.mainKitchen;
  }
}

/// Per-ticket kitchen lifecycle. `ready` tickets leave the live queue.
enum TicketStage {
  pending('New', 'Accept', Icons.notifications_active, Color(0xFF3B82F6)),
  accepted('Accepted', 'Start Cooking', Icons.whatshot, Color(0xFFF59E0B)),
  cooking('Cooking', 'Mark Ready', Icons.check_circle, Color(0xFF10B981)),
  ready('Ready', 'Bumped', Icons.done_all, Color(0xFF10B981));

  const TicketStage(this.label, this.action, this.actionIcon, this.color);
  final String label; // current-state badge text
  final String action; // button label to advance
  final IconData actionIcon;
  final Color color;

  TicketStage get next {
    switch (this) {
      case TicketStage.pending:
        return TicketStage.accepted;
      case TicketStage.accepted:
        return TicketStage.cooking;
      case TicketStage.cooking:
        return TicketStage.ready;
      case TicketStage.ready:
        return TicketStage.ready;
    }
  }
}

/// Time-ageing buckets driving each ticket's colour profile.
enum TicketAging { fresh, warning, critical }

TicketAging agingFor(Duration elapsed) {
  final m = elapsed.inMinutes;
  if (m < 10) return TicketAging.fresh; // green   (< 10 min)
  if (m < 15) return TicketAging.warning; // amber  (10–15 min)
  return TicketAging.critical; // red flashing (> 15 min)
}

/// One line of a station ticket, paired with its stable index inside the
/// parent order so per-item state survives rebuilds.
class StationTicketItem {
  final int lineIndex;
  final OrderLine line;

  const StationTicketItem(this.lineIndex, this.line);
}

/// A per-station slice of an order — the on-screen KOT card.
class StationTicket {
  final String orderId;
  final int billNumber;
  final KitchenStation station;
  final OrderType orderType;
  final String? tableName;
  final DateTime createdAt;
  final List<StationTicketItem> items;

  const StationTicket({
    required this.orderId,
    required this.billNumber,
    required this.station,
    required this.orderType,
    required this.tableName,
    required this.createdAt,
    required this.items,
  });

  /// Stable identity for a station slice of an order.
  String get key => '$orderId::${station.name}';

  String get routeLabel =>
      orderType == OrderType.dineIn && tableName != null
          ? 'Table $tableName'
          : orderType.label;
}

// =============================================================================
// KITCHEN LIFECYCLE STATE
// =============================================================================

class KitchenNotifier extends StateNotifier<Map<String, TicketStage>> {
  KitchenNotifier() : super(const {});

  TicketStage stageOf(String ticketKey) =>
      state[ticketKey] ?? TicketStage.pending;

  /// Advances a ticket to its next lifecycle stage (Accept -> Cooking -> Ready).
  void advance(String ticketKey) {
    final current = stageOf(ticketKey);
    state = {...state, ticketKey: current.next};
  }

  void setStage(String ticketKey, TicketStage stage) {
    state = {...state, ticketKey: stage};
  }
}

final kitchenProvider =
    StateNotifierProvider<KitchenNotifier, Map<String, TicketStage>>((ref) {
  return KitchenNotifier();
});

/// Order ids re-sent to the kitchen from Orders History — flagged on the KDS
/// card so the line cook knows it's a re-fire, not a fresh order.
final resentOrdersProvider = StateProvider<Set<String>>((ref) => <String>{});

// =============================================================================
// DERIVED QUEUE — committed orders -> live station tickets
// =============================================================================

/// Builds, per station, the list of active (non-bumped) tickets from the shared
/// order repository. Oldest-first so the most time-critical sit at the top.
final stationTicketsProvider =
    Provider<Map<KitchenStation, List<StationTicket>>>((ref) {
  final orders = ref.watch(orderRepositoryProvider);
  final stages = ref.watch(kitchenProvider);

  final result = {for (final s in KitchenStation.values) s: <StationTicket>[]};

  // The KDS only shows the current service — tickets from the last 6 hours.
  // (Older orders reloaded from history shouldn't reappear as "overdue".)
  final cutoff = DateTime.now().subtract(const Duration(hours: 6));

  // Oldest order first.
  final ordered = [...orders]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final order in ordered) {
    if (order.createdAt.isBefore(cutoff)) continue;
    final byStation = <KitchenStation, List<StationTicketItem>>{};
    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      final station = KitchenStation.forCategory(line.category);
      byStation.putIfAbsent(station, () => []).add(StationTicketItem(i, line));
    }

    byStation.forEach((station, items) {
      final ticket = StationTicket(
        orderId: order.id,
        billNumber: order.billNumber,
        station: station,
        orderType: order.orderType,
        tableName: order.tableName,
        createdAt: order.createdAt,
        items: items,
      );
      if ((stages[ticket.key] ?? TicketStage.pending) != TicketStage.ready) {
        result[station]!.add(ticket);
      }
    });
  }

  return result;
});

/// Total live tickets across all stations (for the header counter).
final activeTicketCountProvider = Provider<int>((ref) {
  final map = ref.watch(stationTicketsProvider);
  return map.values.fold(0, (sum, list) => sum + list.length);
});
