import 'package:flutter/material.dart';

// =============================================================================
// POS DOMAIN MODELS
// Order channels, product configuration (variations + modifiers), the layered
// bill breakdown and the immutable order record persisted to the repository.
// =============================================================================

/// Omnichannel order type. Each channel drives different billing tiers
/// (service charge for dine-in, packaging for takeaway, delivery fee, …).
enum OrderType {
  dineIn('Dine-In', Icons.restaurant),
  takeaway('Takeaway', Icons.takeout_dining),
  delivery('Delivery', Icons.delivery_dining);

  const OrderType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A mutually-exclusive size/variation choice that shifts the unit price.
class ProductVariation {
  final String label; // e.g. "Small", "Medium", "Large"
  final double priceDelta; // added to the base price when selected

  const ProductVariation(this.label, this.priceDelta);
}

/// An additive, multi-select modifier tag. May carry a surcharge and always
/// contributes an instruction metadata string to the cart line.
class ModifierOption {
  final String label; // e.g. "No Mayo", "Extra Cheese", "Spicy"
  final double priceDelta; // 0 for free instructions, > 0 for paid add-ons

  const ModifierOption(this.label, this.priceDelta);

  bool get isPaid => priceDelta > 0;
}

/// The full set of configurable options offered for a menu item.
class ProductOptionConfig {
  final List<ProductVariation> variations;
  final List<ModifierOption> modifiers;

  const ProductOptionConfig({
    this.variations = const [],
    this.modifiers = const [],
  });

  bool get hasVariations => variations.length > 1;
  bool get hasModifiers => modifiers.isNotEmpty;
  bool get isConfigurable => hasVariations || hasModifiers;
}

/// A single computed tax tier within the bill (e.g. CGST 2.5%, SGST 2.5%).
class TaxLine {
  final String label;
  final double rate; // fractional, e.g. 0.025
  final double amount;

  const TaxLine(this.label, this.rate, this.amount);

  Map<String, dynamic> toMap() =>
      {'label': label, 'rate': rate, 'amount': amount};
  factory TaxLine.fromMap(Map<String, dynamic> m) => TaxLine(
      m['label'] as String,
      (m['rate'] as num).toDouble(),
      (m['amount'] as num).toDouble());
}

/// The fully-resolved, multi-tier monetary breakdown of an active bill.
class BillBreakdown {
  final int itemCount;
  final double subtotal;
  final double discount;
  final List<TaxLine> taxes;
  final double serviceCharge; // dine-in
  final double packagingFee; // takeaway
  final double deliveryFee; // delivery
  final double roundOff;
  final double grandTotal;

  const BillBreakdown({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.taxes,
    required this.serviceCharge,
    required this.packagingFee,
    required this.deliveryFee,
    required this.roundOff,
    required this.grandTotal,
  });

  double get taxTotal => taxes.fold(0.0, (sum, t) => sum + t.amount);

  static const BillBreakdown empty = BillBreakdown(
    itemCount: 0,
    subtotal: 0,
    discount: 0,
    taxes: [],
    serviceCharge: 0,
    packagingFee: 0,
    deliveryFee: 0,
    roundOff: 0,
    grandTotal: 0,
  );

  Map<String, dynamic> toMap() => {
        'itemCount': itemCount,
        'subtotal': subtotal,
        'discount': discount,
        'taxes': taxes.map((t) => t.toMap()).toList(),
        'serviceCharge': serviceCharge,
        'packagingFee': packagingFee,
        'deliveryFee': deliveryFee,
        'roundOff': roundOff,
        'grandTotal': grandTotal,
      };
  factory BillBreakdown.fromMap(Map<String, dynamic> m) => BillBreakdown(
        itemCount: (m['itemCount'] as num).toInt(),
        subtotal: (m['subtotal'] as num).toDouble(),
        discount: (m['discount'] as num).toDouble(),
        taxes: (m['taxes'] as List)
            .map((e) => TaxLine.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        serviceCharge: (m['serviceCharge'] as num).toDouble(),
        packagingFee: (m['packagingFee'] as num).toDouble(),
        deliveryFee: (m['deliveryFee'] as num).toDouble(),
        roundOff: (m['roundOff'] as num).toDouble(),
        grandTotal: (m['grandTotal'] as num).toDouble(),
      );
}

/// Immutable snapshot of one billed line — decoupled from the live cart so a
/// finalised order never mutates after checkout.
class OrderLine {
  final String name;
  final String category; // drives kitchen-station routing (KDS)
  final String? variation;
  final List<String> modifiers;
  final int quantity;
  final double unitPrice;

  const OrderLine({
    required this.name,
    required this.category,
    required this.variation,
    required this.modifiers,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'variation': variation,
        'modifiers': modifiers,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        name: m['name'] as String,
        category: (m['category'] as String?) ?? 'Mains',
        variation: m['variation'] as String?,
        modifiers: List<String>.from(m['modifiers'] as List? ?? const []),
        quantity: (m['quantity'] as num).toInt(),
        unitPrice: (m['unitPrice'] as num).toDouble(),
      );
}

/// Tender channels accepted at checkout.
enum PaymentMethod {
  cash('Cash', Icons.payments_outlined),
  card('Card', Icons.credit_card),
  wallet('Mobile Wallet', Icons.account_balance_wallet_outlined);

  const PaymentMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A single tender against a bill (one bill may have several — a split payment).
class TenderLine {
  final PaymentMethod method;
  final double amount;

  const TenderLine(this.method, this.amount);

  Map<String, dynamic> toMap() => {'method': method.name, 'amount': amount};
  factory TenderLine.fromMap(Map<String, dynamic> m) => TenderLine(
      PaymentMethod.values.byName(m['method'] as String),
      (m['amount'] as num).toDouble());
}

/// Resolved payment for a finalised order: the tenders applied, the total due,
/// the amount tendered and any change returned.
class PaymentInfo {
  final List<TenderLine> tenders;
  final double total;
  final double tendered;
  final double change;

  const PaymentInfo({
    required this.tenders,
    required this.total,
    required this.tendered,
    required this.change,
  });

  bool get isSplit => tenders.length > 1;

  PaymentMethod get primaryMethod =>
      tenders.isNotEmpty ? tenders.first.method : PaymentMethod.cash;

  String get methodLabel =>
      isSplit ? 'Split (${tenders.length})' : primaryMethod.label;

  Map<String, dynamic> toMap() => {
        'tenders': tenders.map((t) => t.toMap()).toList(),
        'total': total,
        'tendered': tendered,
        'change': change,
      };
  factory PaymentInfo.fromMap(Map<String, dynamic> m) => PaymentInfo(
        tenders: (m['tenders'] as List)
            .map((e) => TenderLine.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        total: (m['total'] as num).toDouble(),
        tendered: (m['tendered'] as num).toDouble(),
        change: (m['change'] as num).toDouble(),
      );
}

/// A finalised order persisted to the local repository (offline SQLite cache).
class OrderRecord {
  final String id;
  final int billNumber;
  final OrderType orderType;
  final String? tableName; // bound table for dine-in
  final List<OrderLine> lines;
  final BillBreakdown breakdown;
  final DateTime createdAt;
  final PaymentInfo? payment;

  const OrderRecord({
    required this.id,
    required this.billNumber,
    required this.orderType,
    required this.tableName,
    required this.lines,
    required this.breakdown,
    required this.createdAt,
    this.payment,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'billNumber': billNumber,
        'orderType': orderType.name,
        'tableName': tableName,
        'lines': lines.map((l) => l.toMap()).toList(),
        'breakdown': breakdown.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'payment': payment?.toMap(),
      };
  factory OrderRecord.fromMap(Map<String, dynamic> m) => OrderRecord(
        id: m['id'] as String,
        billNumber: (m['billNumber'] as num).toInt(),
        orderType: OrderType.values.byName(m['orderType'] as String),
        tableName: m['tableName'] as String?,
        lines: (m['lines'] as List)
            .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        breakdown:
            BillBreakdown.fromMap(Map<String, dynamic>.from(m['breakdown'])),
        createdAt: DateTime.parse(m['createdAt'] as String),
        payment: m['payment'] != null
            ? PaymentInfo.fromMap(Map<String, dynamic>.from(m['payment']))
            : null,
      );
}
