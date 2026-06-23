import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/database/db_service.dart';
import '../../domain/models/supplier_model.dart';
import 'inventory_provider.dart';

final suppliersProvider = StateNotifierProvider<SuppliersNotifier, List<SupplierModel>>((ref) {
  return SuppliersNotifier();
});

final restockRequestsProvider = StateNotifierProvider<RestockNotifier, List<RestockRequest>>((ref) {
  return RestockNotifier(ref);
});

/// Supplier ledger, persisted to the MySQL `suppliers` table (SRS 4.4).
class SuppliersNotifier extends StateNotifier<List<SupplierModel>> {
  SuppliersNotifier() : super(const []) {
    _load();
  }

  final _db = DbService.instance;

  static const List<SupplierModel> _seed = [
    SupplierModel(id: 'S-001', name: 'Prime Foods Co.', contact: '+1 555-0101', category: 'Dry Goods', reliability: 97, leadDays: 2, outstandingBalance: 184200),
    SupplierModel(id: 'S-002', name: 'Ocean Fresh', contact: '+1 555-0102', category: 'Seafood', reliability: 88, leadDays: 1, outstandingBalance: 92500),
    SupplierModel(id: 'S-003', name: 'Green Valley Farm', contact: '+1 555-0103', category: 'Produce', reliability: 93, leadDays: 1, outstandingBalance: 41800),
    SupplierModel(id: 'S-004', name: 'Dairy Best', contact: '+1 555-0104', category: 'Dairy', reliability: 99, leadDays: 1, outstandingBalance: 0),
    SupplierModel(id: 'S-005', name: 'Bakery Pro', contact: '+1 555-0105', category: 'Bakery', reliability: 82, leadDays: 2, outstandingBalance: 23400),
    SupplierModel(id: 'S-006', name: 'Spice Traders', contact: '+1 555-0106', category: 'Spices', reliability: 68, leadDays: 5, outstandingBalance: 67900),
    SupplierModel(id: 'S-007', name: 'Beverage Hub', contact: '+1 555-0107', category: 'Beverages', reliability: 91, leadDays: 3, outstandingBalance: 15600),
    SupplierModel(id: 'S-008', name: 'Meat Master', contact: '+1 555-0108', category: 'Meat', reliability: 95, leadDays: 2, outstandingBalance: 128300),
  ];

  SupplierModel _fromRow(Map<String, String?> r) => SupplierModel(
        id: r['id'] ?? '',
        name: r['name'] ?? '',
        contact: r['contact'] ?? '',
        category: r['category'] ?? 'General',
        reliability: double.tryParse(r['reliability'] ?? '') ?? 95,
        leadDays: int.tryParse(r['lead_days'] ?? '') ?? 2,
        outstandingBalance: double.tryParse(r['outstanding_balance'] ?? '') ?? 0,
      );

  Future<void> _load() async {
    if (!_db.isConnected) {
      state = _seed; // offline fallback
      return;
    }
    final rows = await _db.rows('SELECT * FROM suppliers ORDER BY id');
    if (rows.isEmpty) {
      // First run — seed the table so phpMyAdmin shows starter data.
      for (final s in _seed) {
        await _upsert(s);
      }
      state = _seed;
    } else {
      state = rows.map(_fromRow).toList();
    }
  }

  Future<void> _upsert(SupplierModel s) => _db.exec(
        'INSERT INTO suppliers (id,name,contact,category,reliability,lead_days,outstanding_balance) '
        'VALUES (:id,:name,:contact,:category,:rel,:lead,:bal) '
        'ON DUPLICATE KEY UPDATE name=:name, contact=:contact, category=:category, '
        'reliability=:rel, lead_days=:lead, outstanding_balance=:bal',
        {
          'id': s.id,
          'name': s.name,
          'contact': s.contact,
          'category': s.category,
          'rel': s.reliability,
          'lead': s.leadDays,
          'bal': s.outstandingBalance,
        },
      );

  Future<void> addSupplier(SupplierModel s) async {
    state = [...state, s];
    await _upsert(s);
  }

  Future<void> updateSupplier(SupplierModel s) async {
    state = [for (final e in state) if (e.id == s.id) s else e];
    await _upsert(s);
  }

  Future<void> removeSupplier(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _db.exec('DELETE FROM suppliers WHERE id=:id', {'id': id});
  }

  /// Settle (pay off) a supplier's outstanding ledger balance.
  Future<void> settleBalance(String id) async {
    SupplierModel? updated;
    state = [
      for (final e in state)
        if (e.id == id)
          (updated = e.copyWith(outstandingBalance: 0))
        else
          e,
    ];
    if (updated != null) await _upsert(updated);
  }
}

class RestockNotifier extends StateNotifier<List<RestockRequest>> {
  final Ref _ref;
  RestockNotifier(this._ref) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final box = Hive.isBoxOpen('restock_requests') ? Hive.box('restock_requests') : await Hive.openBox('restock_requests');
    final raw = box.get('items', defaultValue: []);
    state = List<Map>.from(raw).map((e) => RestockRequest.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen('restock_requests') ? Hive.box('restock_requests') : await Hive.openBox('restock_requests');
    await box.put('items', state.map((e) => e.toMap()).toList());
  }

  Future<void> createRequest({required String itemName, required String quantityLabel, String? supplierId}) async {
    final suppliers = _ref.read(suppliersProvider);
    final resolvedSupplierId = supplierId ?? (suppliers.isNotEmpty ? suppliers.first.id : null);
    final id = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
    final r = RestockRequest(id: id, itemName: itemName, quantityLabel: quantityLabel, time: DateTime.now(), supplierId: resolvedSupplierId, status: 'pending', resolvedAt: null);
    state = [...state, r];
    await _save();
  }

  Future<void> acceptRequest(String id) async {
    // Update request status
    state = [
      for (final r in state)
        if (r.id == id)
          RestockRequest(
            id: r.id,
            itemName: r.itemName,
            quantityLabel: r.quantityLabel,
            time: r.time,
            supplierId: r.supplierId,
            status: 'received',
            resolvedAt: DateTime.now(),
          )
        else
          r,
    ];
    await _save();
    // Apply stock increment to inventory
    final req = state.firstWhere((e) => e.id == id, orElse: () => state.last);
    final parsed = _parseQuantityLabel(req.quantityLabel);
    if (parsed != null) {
      await _ref.read(inventoryProvider.notifier).incrementStock(itemName: req.itemName, quantity: parsed.$1, unit: parsed.$2);
    }
  }

  (double, String)? _parseQuantityLabel(String label) {
    final raw = label.trim();
    if (raw.isEmpty) return null;

    final spaced = raw.split(RegExp(r'\s+'));
    if (spaced.isNotEmpty) {
      final v = double.tryParse(spaced.first);
      if (v != null) {
        final u = spaced.length > 1 ? spaced.sublist(1).join(' ').trim() : '';
        return (v, u);
      }
    }

    final match = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([^0-9].*)?\s*$').firstMatch(raw);
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;
    final unit = (match.group(2) ?? '').trim();
    return (value, unit);
  }
}
