import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/order_model.dart';
import 'orders_history_provider.dart';

final takeawayTokenProvider = StateProvider<int>((ref) => 1);

final orderProvider = StateNotifierProvider<KitchenNotifier, List<OrderModel>>((ref) {
  return KitchenNotifier(ref);
});

final kitchenProvider = orderProvider;

class KitchenNotifier extends StateNotifier<List<OrderModel>> {
  final Ref _ref;
  KitchenNotifier(this._ref) : super([]);

  void addOrder(OrderModel order) {
    state = [...state, order];
    _ref.read(ordersTimelineProvider.notifier).logCreated(order);
  }

  void updateStatus(String orderId, OrderStatus newStatus) {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: newStatus) else order,
    ];
    _ref.read(ordersTimelineProvider.notifier).logStatus(orderId, newStatus);
  }

  void markAsReady(String orderId) {
    updateStatus(orderId, OrderStatus.ready);
  }

  void completeOrder(String orderId) {
    final idx = state.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _ref.read(ordersTimelineProvider.notifier).logCompleted(state[idx]);
    }
    state = state.where((order) => order.id != orderId).toList();
  }
}

final activeOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(orderProvider);
  return orders.length;
});
