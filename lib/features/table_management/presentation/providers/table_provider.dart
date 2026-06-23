import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/table_model.dart';
 
final selectedTableNameProvider = StateProvider<String?>((ref) => null);

final tableProvider = StateNotifierProvider<TableNotifier, List<TableModel>>((ref) {
  return TableNotifier();
});

class TableNotifier extends StateNotifier<List<TableModel>> {
  TableNotifier() : super([]) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final List<TableModel> tables = [];
    final now = DateTime.now();

    // Deterministically varies the four live states across the floor and
    // backdates occupied tables so elapsed timers read realistically.
    TableStatus statusFor(int i) {
      if (i % 5 == 0) return TableStatus.occupied;
      if (i % 9 == 0) return TableStatus.reserved;
      if (i % 11 == 0) return TableStatus.cleaning;
      if (i % 7 == 0) return TableStatus.billing;
      return TableStatus.available;
    }

    DateTime? occupiedSinceFor(int i, TableStatus status) {
      if (status != TableStatus.occupied && status != TableStatus.billing) {
        return null;
      }
      // 8 .. ~95 minutes ago, spread by index.
      return now.subtract(Duration(minutes: 8 + (i * 7) % 88));
    }

    void addSection(String prefix, String section, int count, int Function(int) seats) {
      for (int i = 1; i <= count; i++) {
        final status = statusFor(i);
        tables.add(
          TableModel(
            id: '$prefix$i',
            name: '$prefix$i',
            seats: seats(i),
            section: section,
            status: status,
            occupiedSince: occupiedSinceFor(i, status),
          ),
        );
      }
    }

    // Generate 100 tables across different sections.
    addSection('G', 'Ground Floor', 40, (i) => i % 4 == 0 ? 6 : (i % 2 == 0 ? 4 : 2));
    addSection('F', 'First Floor', 40, (i) => i % 4 == 0 ? 8 : 4);
    addSection('O', 'Outdoor', 20, (i) => 4);

    state = tables;
  }

  /// Binds an order to a table: marks it occupied and stamps the start time so
  /// the live floor monitor begins its elapsed timer.
  void seatTable(String id, {String? orderId, int? guestCount}) {
    state = [
      for (final table in state)
        if (table.id == id)
          table.copyWith(
            status: TableStatus.occupied,
            occupiedSince: table.occupiedSince ?? DateTime.now(),
            activeOrderId: orderId,
            guestCount: guestCount,
          )
        else
          table,
    ];
  }

  TableModel? byId(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Frees a table: moves it to Cleaning and detaches any active order.
  void closeTable(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          TableModel(
            id: t.id,
            name: t.name,
            seats: t.seats,
            section: t.section,
            status: TableStatus.cleaning,
          )
        else
          t,
    ];
  }

  /// Returns a Cleaning table to service.
  void markAvailable(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          TableModel(
              id: t.id, name: t.name, seats: t.seats, section: t.section)
        else
          t,
    ];
  }

  /// Moves the active seating/order from one table to another empty table.
  void transferTable(String fromId, String toId) {
    final from = byId(fromId);
    if (from == null) return;
    state = [
      for (final t in state)
        if (t.id == fromId)
          TableModel(
              id: t.id, name: t.name, seats: t.seats, section: t.section)
        else if (t.id == toId)
          t.copyWith(
            status: TableStatus.occupied,
            occupiedSince: from.occupiedSince ?? DateTime.now(),
            activeOrderId: from.activeOrderId,
            guestCount: from.guestCount,
          )
        else
          t,
    ];
  }

  /// Merges one table's party into another; the source table is freed.
  void mergeTables(String fromId, String toId) {
    final from = byId(fromId);
    final to = byId(toId);
    if (from == null || to == null) return;
    // Earliest seating time wins; guest counts combine.
    DateTime? earliest;
    if (from.occupiedSince != null && to.occupiedSince != null) {
      earliest = from.occupiedSince!.isBefore(to.occupiedSince!)
          ? from.occupiedSince
          : to.occupiedSince;
    } else {
      earliest = to.occupiedSince ?? from.occupiedSince ?? DateTime.now();
    }
    final combinedGuests = (from.guestCount ?? 0) + (to.guestCount ?? 0);
    state = [
      for (final t in state)
        if (t.id == fromId)
          TableModel(
              id: t.id, name: t.name, seats: t.seats, section: t.section)
        else if (t.id == toId)
          t.copyWith(
            status: TableStatus.occupied,
            occupiedSince: earliest,
            guestCount: combinedGuests == 0 ? null : combinedGuests,
            activeOrderId: to.activeOrderId ?? from.activeOrderId,
          )
        else
          t,
    ];
  }

  void updateTablePosition(String id, double x, double y) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(x: x, y: y) else table,
    ];
  }
  
  void updateTableStatus(String id, TableStatus status) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(status: status) else table,
    ];
  }

  /// Takes a table out of service (maintenance/damage), clearing any seating.
  void setOutOfService(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          TableModel(
              id: t.id,
              name: t.name,
              seats: t.seats,
              section: t.section,
              status: TableStatus.outOfService)
        else
          t,
    ];
  }

  /// Returns an out-of-service table to the available pool.
  void returnToService(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          TableModel(
              id: t.id, name: t.name, seats: t.seats, section: t.section)
        else
          t,
    ];
  }
}
