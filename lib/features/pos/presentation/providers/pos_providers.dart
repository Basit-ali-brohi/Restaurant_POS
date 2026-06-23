import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../menu/domain/models/menu_item_model.dart';
import '../../../cart/domain/models/cart_item_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/models/pos_models.dart';

// =============================================================================
// CHANNEL + DISCOUNT STATE
// =============================================================================

/// Active omnichannel order type (Dine-In / Takeaway / Delivery).
final orderTypeProvider = StateProvider<OrderType>((ref) => OrderType.dineIn);

/// Optional flat discount applied before tax (driven by promos later).
final discountProvider = StateProvider<double>((ref) => 0.0);

/// One-second clock used to refresh elapsed table timers without per-tile
/// controllers. Watch it to rebuild on every tick.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

// =============================================================================
// PRODUCT OPTIONS — category-driven variations & modifier tags
// =============================================================================

/// Resolves the configurable variations + modifier tags for a menu item.
/// Driven by category so the catalogue stays declarative.
ProductOptionConfig optionsForItem(MenuItemModel item) {
  // Item-level definitions from the Menu Editor take precedence over the
  // category defaults so catalogue edits flow straight into the POS.
  if (item.variations.isNotEmpty || item.addOns.isNotEmpty) {
    return ProductOptionConfig(
      variations: [
        for (int i = 0; i < item.variations.length; i++)
          ProductVariation(item.variations[i], i == 0 ? 0.0 : i * 2.0),
      ],
      modifiers: [for (final a in item.addOns) ModifierOption(a, 1.5)],
    );
  }
  switch (item.category) {
    case 'Drinks':
      return const ProductOptionConfig(
        variations: [
          ProductVariation('Small', 0.0),
          ProductVariation('Medium', 2.0),
          ProductVariation('Large', 4.0),
        ],
        modifiers: [
          ModifierOption('Extra Ice', 0.0),
          ModifierOption('No Sugar', 0.0),
          ModifierOption('Fresh Lemon', 0.5),
          ModifierOption('Double Shot', 2.5),
        ],
      );
    case 'Desserts':
      return const ProductOptionConfig(
        variations: [
          ProductVariation('Single', 0.0),
          ProductVariation('Double', 4.0),
        ],
        modifiers: [
          ModifierOption('Extra Ice Cream', 2.0),
          ModifierOption('Serve Warm', 0.0),
          ModifierOption('Nut-Free', 0.0),
        ],
      );
    case 'Drinks ': // defensive: trailing space guard
      return const ProductOptionConfig();
    default:
      // Starters / Mains / Sides — savoury configuration.
      final largeDelta = item.category == 'Mains' ? 6.0 : 3.0;
      return ProductOptionConfig(
        variations: [
          const ProductVariation('Regular', 0.0),
          ProductVariation('Large', largeDelta),
        ],
        modifiers: const [
          ModifierOption('No Mayo', 0.0),
          ModifierOption('Extra Cheese', 1.5),
          ModifierOption('Spicy', 0.0),
          ModifierOption('No Onion', 0.0),
          ModifierOption('Gluten-Free', 2.0),
        ],
      );
  }
}

// =============================================================================
// BILLING ENGINE — multi-tier localized totals
// =============================================================================

class BillRates {
  BillRates._();

  static const double cgst = 0.025; // 2.5%
  static const double sgst = 0.025; // 2.5%
  static const double serviceChargeRate = 0.10; // dine-in only
  static const double packagingPerItem = 0.50; // takeaway only
  static const double deliveryFlatFee = 4.99; // delivery only
}

/// Pure, deterministic bill calculator. Layers subtotal -> discount -> two tax
/// tiers -> channel charge -> rounding into a final [BillBreakdown].
BillBreakdown calculateBill({
  required List<CartItemModel> cart,
  required OrderType type,
  double discount = 0.0,
}) {
  if (cart.isEmpty) return BillBreakdown.empty;

  final int itemCount = cart.fold(0, (sum, c) => sum + c.quantity);
  final double subtotal = cart.fold(0.0, (sum, c) => sum + c.total);
  final double cappedDiscount = discount.clamp(0.0, subtotal);
  final double taxable = subtotal - cappedDiscount;

  final taxes = <TaxLine>[
    TaxLine('CGST', BillRates.cgst, taxable * BillRates.cgst),
    TaxLine('SGST', BillRates.sgst, taxable * BillRates.sgst),
  ];
  final double taxTotal = taxes.fold(0.0, (sum, t) => sum + t.amount);

  final double serviceCharge =
      type == OrderType.dineIn ? taxable * BillRates.serviceChargeRate : 0.0;
  final double packagingFee =
      type == OrderType.takeaway ? itemCount * BillRates.packagingPerItem : 0.0;
  final double deliveryFee =
      type == OrderType.delivery ? BillRates.deliveryFlatFee : 0.0;

  final double preRound =
      taxable + taxTotal + serviceCharge + packagingFee + deliveryFee;
  final double grandTotal = preRound.roundToDouble(); // round to nearest unit
  final double roundOff = grandTotal - preRound;

  return BillBreakdown(
    itemCount: itemCount,
    subtotal: subtotal,
    discount: cappedDiscount,
    taxes: taxes,
    serviceCharge: serviceCharge,
    packagingFee: packagingFee,
    deliveryFee: deliveryFee,
    roundOff: roundOff,
    grandTotal: grandTotal,
  );
}

/// Reactive bill for the live cart, recomputed whenever the cart, channel or
/// discount changes.
final billProvider = Provider<BillBreakdown>((ref) {
  final cart = ref.watch(cartProvider);
  final type = ref.watch(orderTypeProvider);
  final discount = ref.watch(discountProvider);
  return calculateBill(cart: cart, type: type, discount: discount);
});

// =============================================================================
// ORDER REPOSITORY — in-memory stand-in for the local SQLite cache
// =============================================================================

/// Local order store backed by the Hive database ('orders' box). Orders survive
/// app restarts; this is the write path a Cloud MySQL sync will later mirror.
class OrderRepository extends StateNotifier<List<OrderRecord>> {
  OrderRepository() : super(const []) {
    _init();
  }

  int _billSequence = 1000;
  static const _boxName = 'orders';

  /// Latest-first list of committed orders.
  List<OrderRecord> get all => state;

  Future<Box> _box() async => Hive.isBoxOpen(_boxName)
      ? Hive.box(_boxName)
      : await Hive.openBox(_boxName);

  /// Loads persisted orders; seeds demo data on first run.
  Future<void> _init() async {
    try {
      final box = await _box();
      final raw = box.get('records', defaultValue: const <dynamic>[]);
      final list = (raw as List)
          .map((e) => OrderRecord.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isEmpty) {
        _seedDemoOrders();
        await _save();
      } else {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _billSequence =
            list.map((o) => o.billNumber).fold(1000, (a, b) => a > b ? a : b);
        state = list;
      }
    } catch (_) {
      // Corrupt/legacy cache — fall back to fresh seed.
      _seedDemoOrders();
    }
  }

  Future<void> _save() async {
    final box = await _box();
    await box.put('records', state.map((e) => e.toMap()).toList());
  }

  /// Builds a layered breakdown directly from order-line snapshots, used by the
  /// seed path (the live path reuses [calculateBill] from the cart).
  static BillBreakdown _breakdownFromLines(
      List<OrderLine> lines, OrderType type) {
    final itemCount = lines.fold(0, (sum, l) => sum + l.quantity);
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.lineTotal);
    final taxes = <TaxLine>[
      TaxLine('CGST', BillRates.cgst, subtotal * BillRates.cgst),
      TaxLine('SGST', BillRates.sgst, subtotal * BillRates.sgst),
    ];
    final taxTotal = taxes.fold(0.0, (sum, t) => sum + t.amount);
    final service =
        type == OrderType.dineIn ? subtotal * BillRates.serviceChargeRate : 0.0;
    final packaging =
        type == OrderType.takeaway ? itemCount * BillRates.packagingPerItem : 0.0;
    final delivery = type == OrderType.delivery ? BillRates.deliveryFlatFee : 0.0;
    final preRound = subtotal + taxTotal + service + packaging + delivery;
    final grand = preRound.roundToDouble();
    return BillBreakdown(
      itemCount: itemCount,
      subtotal: subtotal,
      discount: 0,
      taxes: taxes,
      serviceCharge: service,
      packagingFee: packaging,
      deliveryFee: delivery,
      roundOff: grand - preRound,
      grandTotal: grand,
    );
  }

  /// Seeds a few backdated kitchen tickets so the KDS opens with live data and
  /// visibly spans the time-ageing thresholds (fresh / warning / critical).
  void _seedDemoOrders() {
    final now = DateTime.now();

    OrderRecord build({
      required OrderType type,
      required String? table,
      required int minutesAgo,
      required List<OrderLine> lines,
    }) {
      return OrderRecord(
        id: const Uuid().v4(),
        billNumber: ++_billSequence,
        orderType: type,
        tableName: table,
        lines: lines,
        breakdown: _breakdownFromLines(lines, type),
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
      );
    }

    state = [
      build(
        type: OrderType.dineIn,
        table: 'G3',
        minutesAgo: 3, // fresh / green
        lines: const [
          OrderLine(
              name: 'Signature Steak',
              category: 'Mains',
              variation: 'Large',
              modifiers: ['No Onion', 'Spicy'],
              quantity: 1,
              unitPrice: 51.0),
          OrderLine(
              name: 'Mojito',
              category: 'Drinks',
              variation: 'Large',
              modifiers: ['Extra Ice'],
              quantity: 2,
              unitPrice: 14.0),
        ],
      ),
      build(
        type: OrderType.delivery,
        table: null,
        minutesAgo: 7, // fresh / green
        lines: const [
          OrderLine(
              name: 'Truffle Fries',
              category: 'Sides',
              variation: 'Regular',
              modifiers: ['Extra Cheese'],
              quantity: 1,
              unitPrice: 13.5),
          OrderLine(
              name: 'Mojito',
              category: 'Drinks',
              variation: 'Small',
              modifiers: [],
              quantity: 1,
              unitPrice: 10.0),
        ],
      ),
      build(
        type: OrderType.takeaway,
        table: null,
        minutesAgo: 13, // warning / yellow
        lines: const [
          OrderLine(
              name: 'Caesar Salad',
              category: 'Starters',
              variation: 'Regular',
              modifiers: ['No Mayo'],
              quantity: 1,
              unitPrice: 14.0),
          OrderLine(
              name: 'Truffle Fries',
              category: 'Sides',
              variation: 'Large',
              modifiers: [],
              quantity: 2,
              unitPrice: 15.0),
        ],
      ),
      build(
        type: OrderType.dineIn,
        table: 'F7',
        minutesAgo: 24, // critical / red flashing
        lines: const [
          OrderLine(
              name: 'Lobster Risotto',
              category: 'Mains',
              variation: 'Regular',
              modifiers: [],
              quantity: 1,
              unitPrice: 38.0),
          OrderLine(
              name: 'Molten Lava Cake',
              category: 'Desserts',
              variation: 'Double',
              modifiers: ['Serve Warm'],
              quantity: 1,
              unitPrice: 20.0),
        ],
      ),
    ];
  }

  /// Commits an order built from a live cart snapshot, assigns the next bill
  /// number, prepends it to the cache and returns the persisted record.
  OrderRecord commitOrder({
    required List<CartItemModel> cart,
    required OrderType type,
    required String? tableName,
    required BillBreakdown breakdown,
    PaymentInfo? payment,
  }) {
    final lines = cart
        .map((c) => OrderLine(
              name: c.menuItem.name,
              category: c.menuItem.category,
              variation: c.variation,
              modifiers: c.modifiers,
              quantity: c.quantity,
              unitPrice: c.unitPrice,
            ))
        .toList(growable: false);

    final record = OrderRecord(
      id: const Uuid().v4(),
      billNumber: ++_billSequence,
      orderType: type,
      tableName: tableName,
      lines: lines,
      breakdown: breakdown,
      createdAt: DateTime.now(),
      payment: payment,
    );

    state = [record, ...state];
    _save(); // persist to the Hive database
    return record;
  }
}

final orderRepositoryProvider =
    StateNotifierProvider<OrderRepository, List<OrderRecord>>(
        (ref) => OrderRepository());
