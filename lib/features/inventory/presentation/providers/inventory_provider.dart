import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import '../../domain/models/inventory_item_model.dart';

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryItemModel>>((ref) {
  return InventoryNotifier();
});

final inventorySelectedFilterProvider = StateProvider<String>((ref) => 'All Items');

class InventoryNotifier extends StateNotifier<List<InventoryItemModel>> {
  InventoryNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final box = Hive.isBoxOpen('inventory') ? Hive.box('inventory') : await Hive.openBox('inventory');
    final raw = box.get('items', defaultValue: []);
    final list = List<Map>.from(raw).map((e) => InventoryItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
    if (list.isEmpty) {
      state = [
        const InventoryItemModel(id: 'I-001', name: 'Chicken Breast', quantity: 12, unit: 'kg', lowThreshold: 5, maxCapacity: 20),
        const InventoryItemModel(id: 'I-002', name: 'French Fries', quantity: 3, unit: 'kg', lowThreshold: 5, maxCapacity: 20),
        const InventoryItemModel(id: 'I-003', name: 'Cooking Oil', quantity: 8, unit: 'L', lowThreshold: 3, maxCapacity: 15),
        const InventoryItemModel(id: 'I-004', name: 'Mozzarella', quantity: 2, unit: 'kg', lowThreshold: 3, maxCapacity: 10),
        const InventoryItemModel(id: 'I-005', name: 'Fresh Lettuce', quantity: 5, unit: 'kg', lowThreshold: 2, maxCapacity: 10),
        const InventoryItemModel(id: 'I-006', name: 'Tomatoes', quantity: 4, unit: 'kg', lowThreshold: 2, maxCapacity: 10),
        const InventoryItemModel(id: 'I-007', name: 'Burger Buns', quantity: 45, unit: 'pcs', lowThreshold: 20, maxCapacity: 100),
        const InventoryItemModel(id: 'I-008', name: 'Cola Syrup', quantity: 15, unit: 'L', lowThreshold: 5, maxCapacity: 30),
      ];
      await _save();
    } else {
      state = list;
    }
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen('inventory') ? Hive.box('inventory') : await Hive.openBox('inventory');
    await box.put('items', state.map((e) => e.toMap()).toList());
  }

  Future<void> incrementStock({required String itemName, required double quantity, required String unit}) async {
    final normalized = itemName.trim().toLowerCase();
    final idx = state.indexWhere((e) => e.name.trim().toLowerCase() == normalized);
    if (idx == -1) {
      final id = 'I-${DateTime.now().millisecondsSinceEpoch}';
      state = [
        ...state,
        InventoryItemModel(id: id, name: itemName.trim(), quantity: quantity, unit: unit, lowThreshold: 1, maxCapacity: quantity * 3),
      ];
    } else {
      final current = state[idx];
      final newQty = current.quantity + quantity;
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) current.copyWith(quantity: newQty, unit: current.unit.isNotEmpty ? current.unit : unit) else state[i],
      ];
    }
    await _save();
  }
}
