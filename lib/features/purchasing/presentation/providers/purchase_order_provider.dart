import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

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
  PurchaseOrderNotifier(this._ref) : super(_seed());

  final Ref _ref;
  static const _uuid = Uuid();
  int _seq = 4200;

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
    return po;
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void _setStatus(String id, POStatus status) {
    state = [
      for (final p in state) if (p.id == id) p.copyWith(status: status) else p,
    ];
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
              'PO #${po.poNumber} · ${po.supplier} · \$${po.total.toStringAsFixed(2)}',
          actor: _ref.read(activeUserProvider).name,
        );
  }
}

final purchaseOrderProvider =
    StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        (ref) => PurchaseOrderNotifier(ref));

/// Active status filter for the PO list (null = all).
final poStatusFilterProvider = StateProvider<POStatus?>((ref) => null);
