import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/stock_models.dart';

/// Branches available for inter-branch transfers (Screen 32).
const List<String> kBranches = [
  'Main Dining',
  'Downtown Branch',
  'Airport Kiosk',
  'Central Warehouse',
];

/// Combined inventory state: the stock lines plus the audit movement log.
class StockState {
  final List<StockItem> items;
  final List<StockMovement> movements;

  const StockState({required this.items, required this.movements});

  StockState copyWith({
    List<StockItem>? items,
    List<StockMovement>? movements,
  }) {
    return StockState(
      items: items ?? this.items,
      movements: movements ?? this.movements,
    );
  }
}

class StockController extends StateNotifier<StockState> {
  StockController() : super(_seed());

  static const _uuid = Uuid();
  static const _actor = 'Admin';

  static StockState _seed() {
    final now = DateTime.now();
    final items = <StockItem>[
      StockItem(
          id: 'S-001',
          name: 'Arborio Rice',
          sku: 'DG-ARB-001',
          category: StockCategory.dryGoods,
          quantity: 45,
          unit: 'kg',
          unitCost: 4.20,
          lowThreshold: 10,
          parLevel: 60),
      StockItem(
          id: 'S-002',
          name: 'Saffron Threads',
          sku: 'SP-SAF-099',
          category: StockCategory.dryGoods,
          quantity: 12,
          unit: 'g',
          unitCost: 45.00,
          lowThreshold: 50,
          parLevel: 200),
      StockItem(
          id: 'S-003',
          name: 'Wagyu Ribeye A5',
          sku: 'MT-WAG-005',
          category: StockCategory.rawIngredients,
          quantity: 8,
          unit: 'kg',
          unitCost: 120.00,
          lowThreshold: 5,
          parLevel: 20,
          expiry: null),
      StockItem(
          id: 'S-004',
          name: 'Truffle Oil (White)',
          sku: 'PT-TRF-002',
          category: StockCategory.rawIngredients,
          quantity: 0.5,
          unit: 'L',
          unitCost: 85.00,
          lowThreshold: 1,
          parLevel: 6),
      StockItem(
          id: 'S-005',
          name: 'Microgreens Mix',
          sku: 'PR-MIC-011',
          category: StockCategory.produce,
          quantity: 2.5,
          unit: 'kg',
          unitCost: 32.00,
          lowThreshold: 2,
          parLevel: 8,
          expiry: null),
      StockItem(
          id: 'S-006',
          name: 'Fresh Mozzarella',
          sku: 'DA-MOZ-014',
          category: StockCategory.dairyEggs,
          quantity: 6,
          unit: 'kg',
          unitCost: 14.00,
          lowThreshold: 3,
          parLevel: 12),
      StockItem(
          id: 'S-007',
          name: 'House Chardonnay',
          sku: 'BR-CHA-021',
          category: StockCategory.barBeverage,
          quantity: 24,
          unit: 'btl',
          unitCost: 11.00,
          lowThreshold: 12,
          parLevel: 48),
      StockItem(
          id: 'S-008',
          name: 'Kraft Takeaway Boxes',
          sku: 'PK-BOX-030',
          category: StockCategory.packaging,
          quantity: 140,
          unit: 'pcs',
          unitCost: 0.35,
          lowThreshold: 100,
          parLevel: 500),
      StockItem(
          id: 'S-009',
          name: 'Heavy Cream',
          sku: 'DA-CRM-018',
          category: StockCategory.dairyEggs,
          quantity: 9,
          unit: 'L',
          unitCost: 3.80,
          lowThreshold: 4,
          parLevel: 20,
          expiry: null),
    ];
    // Backdate one expiry to trigger the "expiring soon" flag.
    final withExpiry = [
      for (final i in items)
        if (i.id == 'S-005')
          i.copyWith(expiry: now.add(const Duration(days: 2)))
        else if (i.id == 'S-009')
          i.copyWith(expiry: now.add(const Duration(days: 3)))
        else
          i,
    ];
    return StockState(items: withExpiry, movements: const []);
  }

  StockItem? byId(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _apply(String itemId, double newQty, StockMovement movement) {
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == itemId) i.copyWith(quantity: newQty) else i,
      ],
      movements: [movement, ...state.movements],
    );
  }

  /// Adds received stock (Screen 29).
  void addStock(String itemId, double qty, {String? note}) {
    final item = byId(itemId);
    if (item == null || qty <= 0) return;
    _apply(
      itemId,
      item.quantity + qty,
      StockMovement(
        id: _uuid.v4(),
        itemId: itemId,
        itemName: item.name,
        type: MovementType.received,
        delta: qty,
        unit: item.unit,
        note: note,
        by: _actor,
        at: DateTime.now(),
      ),
    );
  }

  /// Sets an absolute counted quantity (Screen 30 — manual adjustment).
  void adjustTo(String itemId, double countedQty, {String? note}) {
    final item = byId(itemId);
    if (item == null || countedQty < 0) return;
    final delta = countedQty - item.quantity;
    _apply(
      itemId,
      countedQty,
      StockMovement(
        id: _uuid.v4(),
        itemId: itemId,
        itemName: item.name,
        type: MovementType.adjustment,
        delta: delta,
        unit: item.unit,
        note: note,
        by: _actor,
        at: DateTime.now(),
      ),
    );
  }

  /// Records wastage/loss with a reason tag (Screen 31).
  void recordWastage(String itemId, double qty, WastageReason reason,
      {String? note}) {
    final item = byId(itemId);
    if (item == null || qty <= 0) return;
    final newQty = (item.quantity - qty).clamp(0, double.infinity).toDouble();
    _apply(
      itemId,
      newQty,
      StockMovement(
        id: _uuid.v4(),
        itemId: itemId,
        itemName: item.name,
        type: MovementType.wastage,
        delta: -qty,
        unit: item.unit,
        reason: reason.label,
        note: note,
        by: _actor,
        at: DateTime.now(),
      ),
    );
  }

  /// Moves stock between branches (Screen 32). Logs an out + in pair.
  void transfer(String itemId, double qty, String fromBranch, String toBranch,
      {String? note}) {
    final item = byId(itemId);
    if (item == null || qty <= 0 || fromBranch == toBranch) return;
    final newQty = (item.quantity - qty).clamp(0, double.infinity).toDouble();
    final now = DateTime.now();
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == itemId) i.copyWith(quantity: newQty) else i,
      ],
      movements: [
        StockMovement(
            id: _uuid.v4(),
            itemId: itemId,
            itemName: item.name,
            type: MovementType.transferOut,
            delta: -qty,
            unit: item.unit,
            note: note,
            by: _actor,
            at: now,
            fromBranch: fromBranch,
            toBranch: toBranch),
        ...state.movements,
      ],
    );
  }

  /// Used by Goods Receiving to push received quantities into stock.
  void receiveInto(String itemId, double qty, {String? note}) =>
      addStock(itemId, qty, note: note ?? 'Goods receipt');
}

final stockControllerProvider =
    StateNotifierProvider<StockController, StockState>(
        (ref) => StockController());

final stockItemsProvider = Provider<List<StockItem>>(
    (ref) => ref.watch(stockControllerProvider).items);

final stockMovementsProvider = Provider<List<StockMovement>>(
    (ref) => ref.watch(stockControllerProvider).movements);

/// Active category filter for the stock grid.
final stockCategoryFilterProvider = StateProvider<StockCategory?>((ref) => null);

/// Aggregate KPIs for the inventory dashboard header.
class StockKpis {
  final double totalValue;
  final int lowCount;
  final int outCount;
  final int expiringCount;
  const StockKpis(
      this.totalValue, this.lowCount, this.outCount, this.expiringCount);
}

final stockKpisProvider = Provider<StockKpis>((ref) {
  final items = ref.watch(stockItemsProvider);
  final now = DateTime.now();
  double value = 0;
  int low = 0, out = 0, exp = 0;
  for (final i in items) {
    value += i.valuation;
    if (i.isOut) {
      out++;
    } else if (i.isLow) {
      low++;
    }
    if (i.isExpiringSoon(now)) exp++;
  }
  return StockKpis(value, low, out, exp);
});
