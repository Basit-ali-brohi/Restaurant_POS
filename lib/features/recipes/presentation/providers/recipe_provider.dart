import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';

// =============================================================================
// RECIPE COSTING MODELS + PROVIDERS
// Ingredient-level cost allocation rolled up into food-cost %, margin and a
// system-recommended retail price driven by a target food-cost threshold.
// =============================================================================

class RecipeIngredient {
  final String name;
  final double quantity; // in [unit] (g / ml / pcs)
  final String unit;
  final double costPerUnit; // cost for one [unit]

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
  });

  double get lineCost => quantity * costPerUnit;

  String get quantityLabel {
    final isInt = quantity % 1 == 0;
    final q = isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
    return '$q $unit';
  }
}

class Recipe {
  final String id;
  final String name;
  final String category;
  final int yieldPortions;
  final double sellingPrice;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.yieldPortions,
    required this.sellingPrice,
    required this.ingredients,
  });

  /// Total raw cost for the full yield.
  double get batchCost =>
      ingredients.fold(0.0, (sum, i) => sum + i.lineCost);

  /// Cost to produce one served portion.
  double get costPerPortion =>
      yieldPortions <= 0 ? batchCost : batchCost / yieldPortions;

  /// Food cost as a fraction of the selling price.
  double get foodCostPct =>
      sellingPrice <= 0 ? 0 : costPerPortion / sellingPrice;

  /// Gross margin fraction.
  double get marginPct => sellingPrice <= 0 ? 0 : 1 - foodCostPct;

  /// Gross profit per portion.
  double get profit => sellingPrice - costPerPortion;

  /// System-recommended retail price to hit [targetFoodCost].
  double recommendedPrice(double targetFoodCost) =>
      targetFoodCost <= 0 ? sellingPrice : costPerPortion / targetFoodCost;
}

/// Target food-cost threshold driving the recommended retail price.
final targetFoodCostProvider = StateProvider<double>((ref) => 0.30);

class RecipesNotifier extends StateNotifier<List<Recipe>> {
  RecipesNotifier() : super(_seed) {
    _load();
  }

  final _db = DbService.instance;
  int _seq = 4;

  Recipe _fromRow(Map<String, String?> r) {
    final raw = r['ingredients'];
    final List ing = (raw == null || raw.isEmpty) ? const [] : jsonDecode(raw);
    return Recipe(
      id: r['id'] ?? '',
      name: r['name'] ?? '',
      category: r['category'] ?? '',
      yieldPortions: int.tryParse(r['yield_portions'] ?? '') ?? 1,
      sellingPrice: double.tryParse(r['selling_price'] ?? '') ?? 0,
      ingredients: [
        for (final i in ing)
          RecipeIngredient(
            name: i['name'] as String,
            quantity: (i['quantity'] as num).toDouble(),
            unit: i['unit'] as String,
            costPerUnit: (i['costPerUnit'] as num).toDouble(),
          ),
      ],
    );
  }

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows = await _db.rows('SELECT * FROM recipes ORDER BY id');
    if (rows.isEmpty) {
      for (final rec in _seed) {
        await _persist(rec);
      }
    } else {
      state = rows.map(_fromRow).toList();
      for (final rec in state) {
        final n = int.tryParse(rec.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (n != null && n > _seq) _seq = n;
      }
    }
  }

  Future<void> _persist(Recipe rec) => _db.exec(
        'INSERT INTO recipes (id,name,category,yield_portions,selling_price,ingredients) '
        'VALUES (:id,:name,:cat,:yield,:price,:ing) '
        'ON DUPLICATE KEY UPDATE name=:name, category=:cat, yield_portions=:yield, '
        'selling_price=:price, ingredients=:ing',
        {
          'id': rec.id,
          'name': rec.name,
          'cat': rec.category,
          'yield': rec.yieldPortions,
          'price': rec.sellingPrice,
          'ing': jsonEncode(rec.ingredients
              .map((i) => {
                    'name': i.name,
                    'quantity': i.quantity,
                    'unit': i.unit,
                    'costPerUnit': i.costPerUnit,
                  })
              .toList()),
        },
      );

  Recipe create({
    required String name,
    required String category,
    required int yieldPortions,
    required double sellingPrice,
    required List<RecipeIngredient> ingredients,
  }) {
    final rec = Recipe(
      id: 'R-${(++_seq).toString().padLeft(3, '0')}',
      name: name.trim(),
      category: category,
      yieldPortions: yieldPortions,
      sellingPrice: sellingPrice,
      ingredients: ingredients,
    );
    state = [...state, rec];
    _persist(rec);
    return rec;
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _db.exec('DELETE FROM recipes WHERE id=:id', {'id': id});
  }

  static const List<Recipe> _seed = [
    Recipe(
      id: 'R-001',
      name: 'Saffron Lobster Risotto',
      category: 'Mains',
      yieldPortions: 1,
      sellingPrice: 38.00,
      ingredients: [
        RecipeIngredient(name: 'Arborio Rice', quantity: 90, unit: 'g', costPerUnit: 0.0042),
        RecipeIngredient(name: 'Saffron Threads', quantity: 0.2, unit: 'g', costPerUnit: 45.0),
        RecipeIngredient(name: 'Heavy Cream', quantity: 60, unit: 'ml', costPerUnit: 0.0038),
        RecipeIngredient(name: 'Lobster Meat', quantity: 80, unit: 'g', costPerUnit: 0.062),
        RecipeIngredient(name: 'Parmesan', quantity: 20, unit: 'g', costPerUnit: 0.025),
      ],
    ),
    Recipe(
      id: 'R-002',
      name: 'Wagyu Ribeye Plate',
      category: 'Mains',
      yieldPortions: 1,
      sellingPrice: 120.00,
      ingredients: [
        RecipeIngredient(name: 'Wagyu Ribeye A5', quantity: 220, unit: 'g', costPerUnit: 0.12),
        RecipeIngredient(name: 'Truffle Oil', quantity: 5, unit: 'ml', costPerUnit: 0.085),
        RecipeIngredient(name: 'Microgreens Mix', quantity: 12, unit: 'g', costPerUnit: 0.032),
        RecipeIngredient(name: 'Butter', quantity: 25, unit: 'g', costPerUnit: 0.012),
      ],
    ),
    Recipe(
      id: 'R-003',
      name: 'Truffle Parmesan Fries',
      category: 'Sides',
      yieldPortions: 1,
      sellingPrice: 14.00,
      ingredients: [
        RecipeIngredient(name: 'Potato (cut)', quantity: 200, unit: 'g', costPerUnit: 0.003),
        RecipeIngredient(name: 'Truffle Oil', quantity: 4, unit: 'ml', costPerUnit: 0.085),
        RecipeIngredient(name: 'Parmesan', quantity: 18, unit: 'g', costPerUnit: 0.025),
      ],
    ),
    Recipe(
      id: 'R-004',
      name: 'House Chardonnay (Glass)',
      category: 'Bar',
      yieldPortions: 1,
      sellingPrice: 12.00,
      ingredients: [
        RecipeIngredient(name: 'House Chardonnay', quantity: 150, unit: 'ml', costPerUnit: 0.0147),
      ],
    ),
  ];
}

final recipesProvider =
    StateNotifierProvider<RecipesNotifier, List<Recipe>>(
        (ref) => RecipesNotifier());
