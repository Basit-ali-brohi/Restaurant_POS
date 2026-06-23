import '../../../cart/domain/models/cart_item_model.dart';

enum OrderStatus {
  pending,
  cooking,
  ready,
  completed,
}

enum OrderType {
  dineIn,
  takeaway,
}

class OrderModel {
  final String id;
  final String tableName;
  final List<CartItemModel> items;
  final OrderStatus status;
  final DateTime timestamp;
  final OrderType orderType;

  const OrderModel({
    required this.id,
    required this.tableName,
    required this.items,
    required this.status,
    required this.timestamp,
    this.orderType = OrderType.dineIn,
  });

  OrderModel copyWith({
    String? id,
    String? tableName,
    List<CartItemModel>? items,
    OrderStatus? status,
    DateTime? timestamp,
    OrderType? orderType,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      items: items ?? this.items,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      orderType: orderType ?? this.orderType,
    );
  }
}
