import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../cart/domain/models/cart_item_model.dart';
import '../../../menu/domain/models/menu_item_model.dart';
import '../../../pos/domain/models/pos_models.dart' as pos;
import '../../../pos/presentation/providers/pos_providers.dart';
import '../../domain/models/order_model.dart';

enum OrderEventType { created, statusChanged, completed, voided, canceled, resent }

class TimelineEvent {
  final DateTime time;
  final OrderEventType type;
  final OrderStatus? newStatus;
  final String? note;
  const TimelineEvent({required this.time, required this.type, this.newStatus, this.note});
}

class OrderTimeline {
  final OrderModel snapshot;
  final List<TimelineEvent> events;
  const OrderTimeline({required this.snapshot, this.events = const []});
  OrderTimeline copyWith({OrderModel? snapshot, List<TimelineEvent>? events}) {
    return OrderTimeline(snapshot: snapshot ?? this.snapshot, events: events ?? this.events);
  }
}

final ordersTimelineProvider = StateNotifierProvider<OrdersTimelineNotifier, List<OrderTimeline>>((ref) {
  final notifier = OrdersTimelineNotifier();
  // Rebuild history from the persisted order repository so Orders History
  // survives app restarts (the paid orders are reloaded from MySQL).
  ref.listen<List<pos.OrderRecord>>(orderRepositoryProvider, (_, next) {
    notifier.syncFromOrders(next);
  }, fireImmediately: true);
  return notifier;
});

class OrdersTimelineNotifier extends StateNotifier<List<OrderTimeline>> {
  OrdersTimelineNotifier() : super([]);

  void _upsert(OrderTimeline tl) {
    final idx = state.indexWhere((e) => e.snapshot.id == tl.snapshot.id);
    if (idx == -1) {
      state = [tl, ...state];
    } else {
      final next = [...state];
      next[idx] = tl;
      state = next;
    }
  }

  void logCreated(OrderModel order) {
    final tl = OrderTimeline(
      snapshot: order,
      events: [TimelineEvent(time: DateTime.now(), type: OrderEventType.created)],
    );
    _upsert(tl);
  }

  /// Seeds history entries for any paid orders not already tracked (used to
  /// rebuild Orders History from persisted MySQL orders after a restart).
  void syncFromOrders(List<pos.OrderRecord> orders) {
    final existing = {for (final tl in state) tl.snapshot.id};
    final additions = <OrderTimeline>[];
    for (final o in orders) {
      if (o.payment == null) continue; // only completed transactions
      if (existing.contains(o.id)) continue;
      final items = <CartItemModel>[
        for (var i = 0; i < o.lines.length; i++)
          CartItemModel(
            id: '${o.id}-$i',
            menuItem: MenuItemModel(
              id: '',
              name: o.lines[i].name,
              description: '',
              price: o.lines[i].unitPrice,
              image: '',
              category: o.lines[i].category,
            ),
            quantity: o.lines[i].quantity,
            variation: o.lines[i].variation,
            modifiers: o.lines[i].modifiers,
            unitPriceOverride: o.lines[i].unitPrice,
          ),
      ];
      additions.add(OrderTimeline(
        snapshot: OrderModel(
          id: o.id,
          tableName: o.tableName ?? o.orderType.label,
          items: items,
          status: OrderStatus.cooking,
          timestamp: o.createdAt,
          orderType: o.orderType == pos.OrderType.dineIn
              ? OrderType.dineIn
              : OrderType.takeaway,
        ),
        events: [TimelineEvent(time: o.createdAt, type: OrderEventType.created)],
      ));
    }
    if (additions.isEmpty) return;
    final next = [...additions, ...state]
      ..sort((a, b) => b.snapshot.timestamp.compareTo(a.snapshot.timestamp));
    state = next;
  }

  void logStatus(String orderId, OrderStatus status) {
    final existing = state.firstWhere(
      (e) => e.snapshot.id == orderId,
      orElse: () => OrderTimeline(snapshot: OrderModel(id: orderId, tableName: 'Unknown', items: const [], status: status, timestamp: DateTime.now(), orderType: OrderType.dineIn)),
    );
    final updatedSnapshot = existing.snapshot.copyWith(status: status);
    final tl = existing.copyWith(
      snapshot: updatedSnapshot,
      events: [
        TimelineEvent(time: DateTime.now(), type: OrderEventType.statusChanged, newStatus: status),
        ...existing.events,
      ],
    );
    _upsert(tl);
  }

  void logCompleted(OrderModel order) {
    final existing = state.firstWhere(
      (e) => e.snapshot.id == order.id,
      orElse: () => OrderTimeline(snapshot: order, events: const []),
    );
    final updatedSnapshot = existing.snapshot.copyWith(status: OrderStatus.completed);
    final tl = existing.copyWith(
      snapshot: updatedSnapshot,
      events: [
        TimelineEvent(time: DateTime.now(), type: OrderEventType.completed),
        ...existing.events,
      ],
    );
    _upsert(tl);
  }

  void logVoid(String orderId, String note) {
    final existing = state.firstWhere((e) => e.snapshot.id == orderId, orElse: () => throw ArgumentError('Order not found'));
    final tl = existing.copyWith(
      events: [TimelineEvent(time: DateTime.now(), type: OrderEventType.voided, note: note), ...existing.events],
    );
    _upsert(tl);
  }

  void logCancel(String orderId, String note) {
    final existing = state.firstWhere((e) => e.snapshot.id == orderId, orElse: () => throw ArgumentError('Order not found'));
    final tl = existing.copyWith(
      events: [TimelineEvent(time: DateTime.now(), type: OrderEventType.canceled, note: note), ...existing.events],
    );
    _upsert(tl);
  }

  void logResent(String orderId) {
    final existing = state.firstWhere((e) => e.snapshot.id == orderId, orElse: () => throw ArgumentError('Order not found'));
    final tl = existing.copyWith(
      events: [TimelineEvent(time: DateTime.now(), type: OrderEventType.resent), ...existing.events],
    );
    _upsert(tl);
  }
}
