import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
  return OrdersTimelineNotifier();
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
