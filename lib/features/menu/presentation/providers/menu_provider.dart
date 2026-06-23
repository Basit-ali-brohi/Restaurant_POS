import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/menu_item_model.dart';

/// Mutable menu catalogue — the shared source feeding the POS grid and the
/// Menu Editor. CRUD operations here flow straight into the POS in real time
/// and persist to Hive so edits survive restarts.
class MenuNotifier extends StateNotifier<List<MenuItemModel>> {
  MenuNotifier() : super(_seed) {
    _load();
  }

  static const String _boxName = 'menu';

  Future<void> _load() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    final raw = box.get('items', defaultValue: const []);
    final list = List<Map>.from(raw)
        .map((e) => MenuItemModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    if (list.isNotEmpty) state = list;
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put('items', state.map((e) => e.toMap()).toList());
  }

  static const List<MenuItemModel> _seed = [
    MenuItemModel(
      id: '1',
      name: 'Signature Steak',
      description: 'Premium cut with truffle butter',
      price: 45.00,
      image:
          'https://images.unsplash.com/photo-1600891964092-4316c288032e?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
      category: 'Mains',
      isChefChoice: true,
      sku: 'MEAT-001',
    ),
    MenuItemModel(
      id: '2',
      name: 'Lobster Risotto',
      description: 'Creamy arborio rice with fresh lobster',
      price: 38.00,
      image:
          'https://images.unsplash.com/photo-1595295333158-4742f28fbd85?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
      category: 'Mains',
      isBestSeller: true,
      sku: 'MAIN-012',
    ),
    MenuItemModel(
      id: '3',
      name: 'Truffle Fries',
      description: 'Hand-cut fries with parmesan and truffle oil',
      price: 12.00,
      image:
          'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=800&q=80',
      category: 'Sides',
      isVeg: true,
      sku: 'SIDE-003',
    ),
    MenuItemModel(
      id: '4',
      name: 'Caesar Salad',
      description: 'Crisp romaine with homemade dressing',
      price: 14.00,
      image:
          'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
      category: 'Starters',
      isVeg: true,
      sku: 'STR-004',
    ),
    MenuItemModel(
      id: '5',
      name: 'Molten Lava Cake',
      description: 'Warm chocolate cake with vanilla ice cream',
      price: 16.00,
      image:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
      category: 'Desserts',
      sku: 'DES-005',
    ),
    MenuItemModel(
      id: '6',
      name: 'Mojito',
      description: 'Classic lime and mint cocktail',
      price: 10.00,
      image:
          'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
      category: 'Drinks',
      sku: 'DRK-006',
    ),
  ];

  void addItem(MenuItemModel item) {
    state = [...state, item];
    _save();
  }

  /// Creates a new item with a generated id; returns it.
  MenuItemModel createItem({
    required String name,
    required String description,
    required double price,
    required String category,
    required String sku,
    String image = '',
    bool available = true,
    List<String> variations = const [],
    List<String> addOns = const [],
  }) {
    final item = MenuItemModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      price: price,
      image: image.isEmpty
          ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80'
          : image,
      category: category,
      sku: sku,
      available: available,
      variations: variations,
      addOns: addOns,
    );
    addItem(item);
    return item;
  }

  void updateItem(MenuItemModel updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    _save();
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _save();
  }

  void toggleAvailability(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(available: !item.available) else item,
    ];
    _save();
  }

  /// Configure (or clear) the happy-hour window for an item.
  void setHappyHour(String id,
      {double? price, int? startHour, int? endHour}) {
    state = [
      for (final item in state)
        if (item.id == id)
          (price == null || startHour == null || endHour == null)
              ? item.copyWith(clearHappyHour: true)
              : item.copyWith(
                  happyHourPrice: price,
                  happyHourStart: startHour,
                  happyHourEnd: endHour)
        else
          item,
    ];
    _save();
  }
}

final menuProvider =
    StateNotifierProvider<MenuNotifier, List<MenuItemModel>>(
        (ref) => MenuNotifier());

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredMenuProvider = Provider<List<MenuItemModel>>((ref) {
  final allItems = ref.watch(menuProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  List<MenuItemModel> byCategory = selectedCategory == 'All'
      ? allItems
      : allItems.where((item) => item.category == selectedCategory).toList();

  if (query.isEmpty) return byCategory;

  return byCategory.where((item) {
    return item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query);
  }).toList();
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ['All', 'Starters', 'Mains', 'Sides', 'Desserts', 'Drinks'];
});

/// Editor-facing categories (no "All" pseudo-category).
final editorCategoriesProvider = Provider<List<String>>((ref) {
  return ['Mains', 'Starters', 'Sides', 'Desserts', 'Drinks'];
});

/// Live item count per category, recomputed as the catalogue changes.
final categoryCountsProvider = Provider<Map<String, int>>((ref) {
  final items = ref.watch(menuProvider);
  final counts = <String, int>{};
  for (final item in items) {
    counts[item.category] = (counts[item.category] ?? 0) + 1;
  }
  return counts;
});
