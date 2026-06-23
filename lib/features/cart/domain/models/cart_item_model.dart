import '../../../menu/domain/models/menu_item_model.dart';

class CartItemModel {
  final String id;
  final MenuItemModel menuItem;
  final int quantity;

  /// Selected variation label (e.g. "Large"), or null for the default size.
  final String? variation;

  /// Free-form instruction metadata appended from modifier tags
  /// (e.g. "No Mayo", "Extra Cheese", "Spicy").
  final List<String> modifiers;

  /// Effective per-unit price including the variation delta and any paid
  /// modifier surcharges. Falls back to the base menu price when null so
  /// legacy call-sites that only pass [menuItem] keep working unchanged.
  final double? unitPriceOverride;

  final String? note;

  const CartItemModel({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.variation,
    this.modifiers = const [],
    this.unitPriceOverride,
    this.note,
  });

  /// The price charged for a single unit of this configured line item.
  double get unitPrice => unitPriceOverride ?? menuItem.price;

  /// Line total = effective unit price × quantity.
  double get total => unitPrice * quantity;

  /// Stable signature used to merge identical configurations into one line.
  String get configKey =>
      '${menuItem.id}|${variation ?? ''}|${(List<String>.from(modifiers)..sort()).join(',')}|${note ?? ''}';

  CartItemModel copyWith({
    int? quantity,
    String? variation,
    List<String>? modifiers,
    double? unitPriceOverride,
    String? note,
  }) {
    return CartItemModel(
      id: id,
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      variation: variation ?? this.variation,
      modifiers: modifiers ?? this.modifiers,
      unitPriceOverride: unitPriceOverride ?? this.unitPriceOverride,
      note: note ?? this.note,
    );
  }
}
