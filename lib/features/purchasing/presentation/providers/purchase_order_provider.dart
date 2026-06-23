import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/db_service.dart';
import '../../../inventory/presentation/providers/stock_provider.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/models/purchase_order.dart';

/// Suppliers available when raising a PO.
const List<String> kPoSuppliers = [
  'Prime Foods Co.',
  'Ocean Fresh',
  'Green Valley Farm',
  'Dairy Best',
  'Global Spices Co.',
];

class PurchaseOrderNotifier extends StateNotifier<List<PurchaseOrder>> {
  PurchaseOrderNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;
  final _db = DbService.instance;
  static const _uuid = Uuid();
  int _seq = 4200;

  static String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  Future<void> _load() async {
    if (!_db.isConnected) {
      state = _seed();
      return;
    }
    final headers =
        await _db.rows('SELECT * FROM purchase_orders ORDER BY po_number');
    if (headers.isEmpty) {
      final seed = _seed();
      for (final po in seed) {
        await _insertPO(po);
      }
      state = seed;
      _seq = 4204;
      return;
    }
    final out = <PurchaseOrder>[];
    for (final h in headers) {
      final lineRows = await _db.rows(
          'SELECT * FROM purchase_order_lines WHERE po_id=:id', {'id': h['id']});
      out.add(PurchaseOrder(
        id: h['id'] ?? '',
        poNumber: int.tryParse(h['po_number'] ?? '') ?? 0,
        supplier: h['supplier'] ?? '',
        status: POStatus.values.firstWhere((s) => s.name == h['status'],
            orElse: () => POStatus.draft),
        createdAt: DateTime.tryParse(h['created_at'] ?? '') ?? DateTime.now(),
        note: h['note'],
        lines: [
          for (final l in lineRows)
            POLine(
              itemId: l['item_id'] ?? '',
              name: l['name'] ?? '',
              unit: l['unit'] ?? '',
              quantity: double.tryParse(l['quantity'] ?? '') ?? 0,
              unitCost: double.tryParse(l['unit_cost'] ?? '') ?? 0,
            ),
        ],
      ));
    }
    out.sort((a, b) => b.poNumber.compareTo(a.poNumber));
    state = out;
    for (final p in out) {
      if (p.poNumber > _seq) _seq = p.poNumber;
    }
  }

  Future<void> _insertPO(PurchaseOrder po) async {
    await _db.exec(
      'INSERT INTO purchase_orders (id,po_number,supplier,status,created_at,note) '
      'VALUES (:id,:num,:sup,:status,:created,:note) '
      'ON DUPLICATE KEY UPDATE status=:status, note=:note',
      {
        'id': po.id,
        'num': po.poNumber,
        'sup': po.supplier,
        'status': po.status.name,
        'created': _fmt(po.createdAt),
        'note': po.note,
      },
    );
    await _db.exec(
        'DELETE FROM purchase_order_lines WHERE po_id=:id', {'id': po.id});
    for (final l in po.lines) {
      await _db.exec(
        'INSERT INTO purchase_order_lines (po_id,item_id,name,unit,quantity,unit_cost) '
        'VALUES (:po,:item,:name,:unit,:qty,:cost)',
        {
          'po': po.id,
          'item': l.itemId,
          'name': l.name,
          'unit': l.unit,
          'qty': l.quantity,
          'cost': l.unitCost,
        },
      );
    }
  }

  static List<PurchaseOrder> _seed() {
    final now = DateTime.now();
    return [
      PurchaseOrder(
        id: 'p1',
        poNumber: 4201,
        supplier: 'Global Spices Co.',
        status: POStatus.pendingApproval,
        createdAt: now.subtract(const Duration(hours: 3)),
        lines: const [
          POLine(itemId: 'S-002', name: 'Saffron Threads', unit: 'g', quantity: 100, unitCost: 45.0),
          POLine(itemId: 'S-001', name: 'Arborio Rice', unit: 'kg', quantity: 20, unitCost: 4.20),
        ],
      ),
      PurchaseOrder(
        id: 'p2',
        poNumber: 4202,
        supplier: 'Prime Foods Co.',
        status: POStatus.draft,
        createdAt: now.subtract(const Duration(hours: 1)),
        lines: const [
          POLine(itemId: 'S-003', name: 'Wagyu Ribeye A5', unit: 'kg', quantity: 6, unitCost: 120.0),
        ],
      ),
      PurchaseOrder(
        id: 'p3',
        poNumber: 4203,
        supplier: 'Ocean Fresh',
        status: POStatus.dispatched,
        createdAt: now.subtract(const Duration(days: 1)),
        lines: const [
          POLine(itemId: 'S-004', name: 'Truffle Oil (White)', unit: 'L', quantity: 4, unitCost: 85.0),
          POLine(itemId: 'S-008', name: 'Kraft Takeaway Boxes', unit: 'pcs', quantity: 300, unitCost: 0.35),
        ],
      ),
      PurchaseOrder(
        id: 'p4',
        poNumber: 4204,
        supplier: 'Dairy Best',
        status: POStatus.received,
        createdAt: now.subtract(const Duration(days: 2)),
        lines: const [
          POLine(itemId: 'S-006', name: 'Fresh Mozzarella', unit: 'kg', quantity: 10, unitCost: 14.0),
        ],
      ),
    ];
  }

  // --- CRUD ------------------------------------------------------------------

  PurchaseOrder createDraft({
    required String supplier,
    required List<POLine> lines,
    String? note,
  }) {
    final po = PurchaseOrder(
      id: _uuid.v4(),
      poNumber: ++_seq,
      supplier: supplier,
      lines: lines,
      status: POStatus.draft,
      createdAt: DateTime.now(),
      note: note,
    );
    state = [po, ...state];
    _insertPO(po);
    return po;
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _db.exec('DELETE FROM purchase_order_lines WHERE po_id=:id', {'id': id});
    _db.exec('DELETE FROM purchase_orders WHERE id=:id', {'id': id});
  }

  void _setStatus(String id, POStatus status) {
    state = [
      for (final p in state) if (p.id == id) p.copyWith(status: status) else p,
    ];
    _db.exec('UPDATE purchase_orders SET status=:s WHERE id=:id',
        {'s': status.name, 'id': id});
  }

  // --- Lifecycle -------------------------------------------------------------

  void submit(String id) => _setStatus(id, POStatus.pendingApproval);

  void approve(String id) {
    _setStatus(id, POStatus.approved);
    _audit(id, 'Purchase order approved');
  }

  void reject(String id) {
    _setStatus(id, POStatus.rejected);
    _audit(id, 'Purchase order rejected');
  }

  void dispatch(String id) => _setStatus(id, POStatus.dispatched);

  /// Goods receipt — pushes the ordered quantities into the live stock ledger
  /// and marks the PO received (SRS 4.3 "Automatic Inventory Ledger Update").
  void receive(String id) {
    final po = state.firstWhere((p) => p.id == id);
    final stock = _ref.read(stockControllerProvider.notifier);
    for (final line in po.lines) {
      stock.receiveInto(line.itemId, line.quantity,
          note: 'PO #${po.poNumber} · ${po.supplier}');
    }
    _setStatus(id, POStatus.received);
    _audit(id, 'Goods received into inventory');
  }

  void _audit(String id, String action) {
    final po = state.firstWhere((p) => p.id == id);
    _ref.read(auditTrailProvider.notifier).log(
          category: AuditCategory.inventory,
          action: action,
          detail:
              'PO #${po.poNumber} · ${po.supplier} · PKR ${po.total.toStringAsFixed(2)}',
          actor: _ref.read(activeUserProvider).name,
        );
  }
}

final purchaseOrderProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        (ref) => PurchaseOrderNotifier(ref));

/// Active status filter for the PO list (null = all).
final poStatusFilterProvider = StateProvider<POStatus?>((ref) => null);
