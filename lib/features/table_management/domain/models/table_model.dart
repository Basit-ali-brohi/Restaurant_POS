enum TableStatus { available, occupied, reserved, cleaning, billing, outOfService }

class TableModel {
  final String id;
  final String name;
  final int seats;
  final TableStatus status;
  final double x;
  final double y;
  final String? activeOrderId;
  final DateTime? occupiedSince;
  final String? waiterName;
  final int? guestCount;
  final String section;

  TableModel({
    required this.id,
    required this.name,
    required this.seats,
    this.status = TableStatus.available,
    this.x = 0,
    this.y = 0,
    this.activeOrderId,
    this.occupiedSince,
    this.waiterName,
    this.guestCount,
    this.section = 'Ground Floor',
  });

  TableModel copyWith({
    String? id,
    String? name,
    int? seats,
    TableStatus? status,
    double? x,
    double? y,
    String? activeOrderId,
    DateTime? occupiedSince,
    String? waiterName,
    int? guestCount,
    String? section,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      x: x ?? this.x,
      y: y ?? this.y,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      waiterName: waiterName ?? this.waiterName,
      guestCount: guestCount ?? this.guestCount,
      section: section ?? this.section,
    );
  }
}
