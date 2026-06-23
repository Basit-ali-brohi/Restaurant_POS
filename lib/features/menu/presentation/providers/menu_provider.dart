import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/db_service.dart';
import '../../domain/models/menu_item_model.dart';

/// Mutable menu catalogue — the shared source feeding the POS grid and the
/// Menu Editor. CRUD operations here flow straight into the POS in real time
/// and persist to the MySQL `menu_items` table so edits survive restarts.
class MenuNotifier extends StateNotifier<List<MenuItemModel>> {
  MenuNotifier() : super(_seed) {
    _load();
  }

  final _db = DbService.instance;

  MenuItemModel _fromRow(Map<String, String?> r) {
    List<String> list(String? raw) => (raw == null || raw.isEmpty)
        ? const []
        : List<String>.from(jsonDecode(raw) as List);
    int? toInt(String? v) => v == null || v.isEmpty ? null : int.tryParse(v);
    double? toDbl(String? v) =>
        v == null || v.isEmpty ? null : double.tryParse(v);
    return MenuItemModel(
      id: r['id'] ?? '',
      name: r['name'] ?? '',
      description: r['description'] ?? '',
      price: double.tryParse(r['price'] ?? '') ?? 0,
      image: r['image'] ?? '',
      category: r['category'] ?? '',
      isBestSeller: (r['is_best_seller'] ?? '0') == '1',
      isChefChoice: (r['is_chef_choice'] ?? '0') == '1',
      isVeg: (r['is_veg'] ?? '0') == '1',
      sku: r['sku'] ?? '',
      available: (r['available'] ?? '1') == '1',
      variations: list(r['variations']),
      addOns: list(r['addons']),
      happyHourPrice: toDbl(r['happy_hour_price']),
      happyHourStart: toInt(r['happy_hour_start']),
      happyHourEnd: toInt(r['happy_hour_end']),
    );
  }

  Future<void> _load() async {
    if (!_db.isConnected) return; // keep seed
    final rows = await _db.rows('SELECT * FROM menu_items');
    if (rows.isEmpty) {
      for (final m in _seed) {
        await _upsert(m);
      }
    } else {
      state = rows.map(_fromRow).toList();
    }
  }

  Future<void> _upsert(MenuItemModel m) => _db.exec(
        'INSERT INTO menu_items (id,name,description,price,image,category,'
        'is_best_seller,is_chef_choice,is_veg,sku,available,variations,addons,'
        'happy_hour_price,happy_hour_start,happy_hour_end) '
        'VALUES (:id,:name,:desc,:price,:image,:cat,:best,:chef,:veg,:sku,:avail,'
        ':vars,:addons,:hhp,:hhs,:hhe) '
        'ON DUPLICATE KEY UPDATE name=:name, description=:desc, price=:price, '
        'image=:image, category=:cat, is_best_seller=:best, is_chef_choice=:chef, '
        'is_veg=:veg, sku=:sku, available=:avail, variations=:vars, addons=:addons, '
        'happy_hour_price=:hhp, happy_hour_start=:hhs, happy_hour_end=:hhe',
        {
          'id': m.id,
          'name': m.name,
          'desc': m.description,
          'price': m.price,
          'image': m.image,
          'cat': m.category,
          'best': m.isBestSeller ? 1 : 0,
          'chef': m.isChefChoice ? 1 : 0,
          'veg': m.isVeg ? 1 : 0,
          'sku': m.sku,
          'avail': m.available ? 1 : 0,
          'vars': jsonEncode(m.variations),
          'addons': jsonEncode(m.addOns),
          'hhp': m.happyHourPrice,
          'hhs': m.happyHourStart,
          'hhe': m.happyHourEnd,
        },
      );

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
    _upsert(item);
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
    _upsert(updated);
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _db.exec('DELETE FROM menu_items WHERE id=:id', {'id': id});
  }

  void toggleAvailability(String id) {
    MenuItemModel? changed;
    state = [
      for (final item in state)
        if (item.id == id)
          (changed = item.copyWith(available: !item.available))
        else
          item,
    ];
    if (changed != null) _upsert(changed);
  }

  /// Configure (or clear) the happy-hour window for an item.
  void setHappyHour(String id,
      {double? price, int? startHour, int? endHour}) {
    MenuItemModel? changed;
    state = [
      for (final item in state)
        if (item.id == id)
          (changed = (price == null || startHour == null || endHour == null)
              ? item.copyWith(clearHappyHour: true)
              : item.copyWith(
                  happyHourPrice: price,
                  happyHourStart: startHour,
                  happyHourEnd: endHour))
        else
          item,
    ];
    if (changed != null) _upsert(changed);
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
