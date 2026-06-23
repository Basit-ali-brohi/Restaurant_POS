class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isBestSeller;
  final bool isChefChoice;
  final bool isVeg;

  /// Stock keeping unit shown in the menu editor.
  final String sku;

  /// Whether the item is currently available for ordering (else "Sold Out").
  final bool available;

  /// Item-level variation labels (e.g. Small, Medium, Large). When set these
  /// drive the POS customization sheet in place of category defaults.
  final List<String> variations;

  /// Item-level add-on / modifier labels (e.g. Extra Cheese, Extra Sauce).
  final List<String> addOns;

  /// SRS 5.x — Time-based ("Happy Hour") pricing. When [happyHourPrice] is set
  /// and the current hour falls within [happyHourStart, happyHourEnd), the item
  /// is sold at the discounted price. Hours are 0–23; the window may wrap past
  /// midnight (e.g. start 22, end 2).
  final double? happyHourPrice;
  final int? happyHourStart;
  final int? happyHourEnd;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.isBestSeller = false,
    this.isChefChoice = false,
    this.isVeg = false,
    this.sku = '',
    this.available = true,
    this.variations = const [],
    this.addOns = const [],
    this.happyHourPrice,
    this.happyHourStart,
    this.happyHourEnd,
  });

  /// Whether a happy-hour window is configured for this item.
  bool get hasHappyHour =>
      happyHourPrice != null && happyHourStart != null && happyHourEnd != null;

  /// Whether the happy-hour window is active at [now] (defaults to wall clock).
  bool isHappyHourActive([DateTime? now]) {
    if (!hasHappyHour) return false;
    final h = (now ?? DateTime.now()).hour;
    final start = happyHourStart!;
    final end = happyHourEnd!;
    if (start == end) return false;
    if (start < end) return h >= start && h < end;
    // Window wraps past midnight.
    return h >= start || h < end;
  }

  /// The price the customer pays right now, accounting for happy hour.
  double effectivePrice([DateTime? now]) =>
      isHappyHourActive(now) ? happyHourPrice! : price;

  /// Human-readable happy-hour window, e.g. "16:00–18:00".
  String get happyHourLabel {
    if (!hasHappyHour) return '';
    String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
    return '${hh(happyHourStart!)}–${hh(happyHourEnd!)}';
  }

  MenuItemModel copyWith({
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    bool? isBestSeller,
    bool? isChefChoice,
    bool? isVeg,
    String? sku,
    bool? available,
    List<String>? variations,
    List<String>? addOns,
    double? happyHourPrice,
    int? happyHourStart,
    int? happyHourEnd,
    bool clearHappyHour = false,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isChefChoice: isChefChoice ?? this.isChefChoice,
      isVeg: isVeg ?? this.isVeg,
      sku: sku ?? this.sku,
      available: available ?? this.available,
      variations: variations ?? this.variations,
      addOns: addOns ?? this.addOns,
      happyHourPrice:
          clearHappyHour ? null : (happyHourPrice ?? this.happyHourPrice),
      happyHourStart:
          clearHappyHour ? null : (happyHourStart ?? this.happyHourStart),
      happyHourEnd: clearHappyHour ? null : (happyHourEnd ?? this.happyHourEnd),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'category': category,
        'isBestSeller': isBestSeller,
        'isChefChoice': isChefChoice,
        'isVeg': isVeg,
        'sku': sku,
        'available': available,
        'variations': variations,
        'addOns': addOns,
        'happyHourPrice': happyHourPrice,
        'happyHourStart': happyHourStart,
        'happyHourEnd': happyHourEnd,
      };

  factory MenuItemModel.fromMap(Map<String, dynamic> map) => MenuItemModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: (map['description'] as String?) ?? '',
        price: (map['price'] as num).toDouble(),
        image: (map['image'] as String?) ?? '',
        category: map['category'] as String,
        isBestSeller: (map['isBestSeller'] as bool?) ?? false,
        isChefChoice: (map['isChefChoice'] as bool?) ?? false,
        isVeg: (map['isVeg'] as bool?) ?? false,
        sku: (map['sku'] as String?) ?? '',
        available: (map['available'] as bool?) ?? true,
        variations: List<String>.from(map['variations'] as List? ?? const []),
        addOns: List<String>.from(map['addOns'] as List? ?? const []),
        happyHourPrice: (map['happyHourPrice'] as num?)?.toDouble(),
        happyHourStart: (map['happyHourStart'] as num?)?.toInt(),
        happyHourEnd: (map['happyHourEnd'] as num?)?.toInt(),
      );
}
