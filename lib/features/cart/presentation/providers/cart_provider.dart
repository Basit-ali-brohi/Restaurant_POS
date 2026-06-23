import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../menu/domain/models/menu_item_model.dart';
import '../../domain/models/cart_item_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addItem(MenuItemModel item) {
    // Check if item already exists with same modifiers (empty for now)
    final existingIndex = state.indexWhere((element) => element.menuItem.id == item.id && element.modifiers.isEmpty);
    
    if (existingIndex != -1) {
      // Increment quantity
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Add new item
      state = [
        ...state,
        CartItemModel(
          id: const Uuid().v4(),
          menuItem: item,
          quantity: 1,
        ),
      ];
    }
  }

  /// Adds a fully-configured line item carrying a chosen variation, modifier
  /// instruction tags and an effective per-unit price. Identical configurations
  /// (same item + variation + modifiers + note) merge by incrementing quantity;
  /// distinct configurations become their own cart lines.
  void addConfigured({
    required MenuItemModel item,
    String? variation,
    List<String> modifiers = const [],
    required double unitPrice,
    String? note,
    int quantity = 1,
  }) {
    final candidate = CartItemModel(
      id: const Uuid().v4(),
      menuItem: item,
      quantity: quantity,
      variation: variation,
      modifiers: modifiers,
      unitPriceOverride: unitPrice,
      note: note,
    );

    final existingIndex =
        state.indexWhere((element) => element.configKey == candidate.configKey);

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existing.copyWith(quantity: existing.quantity + quantity),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, candidate];
    }
  }

  void incrementQuantity(String cartItemId) {
    state = [
      for (final item in state)
        if (item.id == cartItemId) item.copyWith(quantity: item.quantity + 1) else item,
    ];
  }

  void decrementQuantity(String cartItemId) {
    final itemIndex = state.indexWhere((element) => element.id == cartItemId);
    if (itemIndex == -1) return;

    final item = state[itemIndex];
    if (item.quantity > 1) {
      state = [
        ...state.sublist(0, itemIndex),
        item.copyWith(quantity: item.quantity - 1),
        ...state.sublist(itemIndex + 1),
      ];
    } else {
      // Remove item
      state = [
        ...state.sublist(0, itemIndex),
        ...state.sublist(itemIndex + 1),
      ];
    }
  }

  void clear() {
    state = [];
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.total);
});
