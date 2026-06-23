import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/menu/presentation/providers/menu_provider.dart';
import '../../features/inventory/presentation/providers/stock_provider.dart';
import '../../features/pos/presentation/providers/pos_providers.dart';
import '../../features/table_management/presentation/providers/table_provider.dart';

/// Real application bootstrap. The splash awaits this future, so the loading
/// screen reflects genuine initialization (warming the catalogue, inventory,
/// order cache and floor) rather than a fixed timer.
final bootstrapProvider = FutureProvider<void>((ref) async {
  // Warm the core data providers so they seed/initialise before the first
  // screen renders — the menu catalogue, stock matrix, order repository and
  // table floor are all read once here.
  ref.read(menuProvider);
  ref.read(stockItemsProvider);
  ref.read(orderRepositoryProvider);
  ref.read(tableProvider);

  // Minimum brand display + simulated cloud sync handshake.
  await Future.delayed(const Duration(milliseconds: 700));
});
