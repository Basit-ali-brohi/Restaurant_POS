import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

/// Logical grouping for the sidebar navigation sections.
enum ModuleGroup { operations, management }

/// Every top-level destination surfaced by the premium [AppShell].
///
/// Each module declares the legacy [dashboardIndexProvider] index it maps onto
/// (when one exists) so the shell stays in lock-step with the existing feature
/// screens — preserving cross-screen flows such as Tables -> Menu that drive
/// [dashboardIndexProvider] directly.
enum PosModule {
  // --- Operations -----------------------------------------------------------
  overview(
    label: 'Dashboard Overview',
    subtitle: 'Live business intelligence',
    icon: Icons.space_dashboard_outlined,
    group: ModuleGroup.operations,
    legacyIndex: null,
  ),
  pos(
    label: 'POS Counter',
    subtitle: 'Checkout & order entry',
    icon: Icons.point_of_sale_outlined,
    group: ModuleGroup.operations,
    legacyIndex: 1, // MenuScreen
  ),
  floor(
    label: 'Floor & Tables',
    subtitle: 'Live table monitor',
    icon: Icons.table_restaurant_outlined,
    group: ModuleGroup.operations,
    legacyIndex: 0, // TableSelectionScreen
  ),
  kitchen(
    label: 'Kitchen Display',
    subtitle: 'KDS ticket rail',
    icon: Icons.soup_kitchen_outlined,
    group: ModuleGroup.operations,
    legacyIndex: 2, // KDSScreen
  ),
  inventory(
    label: 'Stock & Recipes',
    subtitle: 'Costing & inventory',
    icon: Icons.inventory_2_outlined,
    group: ModuleGroup.operations,
    legacyIndex: 4, // InventoryScreen
  ),
  menu(
    label: 'Menu Editor',
    subtitle: 'Catalogue & modifiers',
    icon: Icons.menu_book_outlined,
    group: ModuleGroup.operations,
    legacyIndex: null, // shell-only screen
  ),
  recipeCosting(
    label: 'Recipe Costing',
    subtitle: 'Yields & margins',
    icon: Icons.calculate_outlined,
    group: ModuleGroup.management,
    legacyIndex: null, // shell-only screen
  ),
  crm(
    label: 'CRM & Loyalty',
    subtitle: 'Customers & points',
    icon: Icons.card_membership_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  onlineOrders(
    label: 'Online Orders',
    subtitle: 'Web & aggregators',
    icon: Icons.language_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  delivery(
    label: 'Delivery Hub',
    subtitle: 'Fleet & riders',
    icon: Icons.two_wheeler_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  feedback(
    label: 'Feedback',
    subtitle: 'Ratings & complaints',
    icon: Icons.reviews_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  notifications(
    label: 'Notifications',
    subtitle: 'Alerts & messages',
    icon: Icons.notifications_none,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  branches(
    label: 'Multi-Branch',
    subtitle: 'Network performance',
    icon: Icons.store_mall_directory_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  finance(
    label: 'Finance & P&L',
    subtitle: 'Ledger & reports',
    icon: Icons.account_balance_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  tax(
    label: 'Tax Settings',
    subtitle: 'GST/VAT & FBR sync',
    icon: Icons.receipt_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),
  audit(
    label: 'Audit Log',
    subtitle: 'Forensic system log',
    icon: Icons.fact_check_outlined,
    group: ModuleGroup.management,
    legacyIndex: null,
  ),

  // --- Management -----------------------------------------------------------
  insights(
    label: 'Business Insights',
    subtitle: 'Analytics & reporting',
    icon: Icons.insights_outlined,
    group: ModuleGroup.management,
    legacyIndex: 3, // InsightsScreen
  ),
  suppliers(
    label: 'Suppliers',
    subtitle: 'Purchasing & vendors',
    icon: Icons.local_shipping_outlined,
    group: ModuleGroup.management,
    legacyIndex: 5, // SuppliersScreen
  ),
  purchasing(
    label: 'Purchase Orders',
    subtitle: 'Requisitions & receiving',
    icon: Icons.shopping_cart_checkout_outlined,
    group: ModuleGroup.management,
    legacyIndex: null, // shell-only screen
  ),
  reservations(
    label: 'Reservations',
    subtitle: 'Bookings & registry',
    icon: Icons.event_seat_outlined,
    group: ModuleGroup.management,
    legacyIndex: null, // shell-only screen
  ),
  staff(
    label: 'Staff',
    subtitle: 'Team & roles',
    icon: Icons.groups_outlined,
    group: ModuleGroup.management,
    legacyIndex: 6, // StaffScreen
  ),
  history(
    label: 'Orders History',
    subtitle: 'Past tickets & audit',
    icon: Icons.history_outlined,
    group: ModuleGroup.management,
    legacyIndex: 7, // OrdersHistoryScreen
  ),
  sales(
    label: 'Sales & Transactions',
    subtitle: 'Payments & receipts',
    icon: Icons.receipt_long_outlined,
    group: ModuleGroup.management,
    legacyIndex: 8, // TransactionsScreen
  ),
  shift(
    label: 'Shift Management',
    subtitle: 'Open / close & cash',
    icon: Icons.schedule_outlined,
    group: ModuleGroup.management,
    legacyIndex: 9, // ShiftScreen
  ),
  settings(
    label: 'Settings',
    subtitle: 'Configuration',
    icon: Icons.settings_outlined,
    group: ModuleGroup.management,
    legacyIndex: 10, // SettingsScreen
  );

  const PosModule({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.group,
    required this.legacyIndex,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final ModuleGroup group;

  /// Corresponding [dashboardIndexProvider] value, or `null` for shell-only
  /// modules (the Overview) that have no legacy screen.
  final int? legacyIndex;

  /// Modules belonging to [group], in declaration order.
  static List<PosModule> inGroup(ModuleGroup group) =>
      PosModule.values.where((m) => m.group == group).toList(growable: false);

  /// Resolve a legacy dashboard index back to a shell module, if one maps.
  static PosModule? fromLegacyIndex(int index) {
    for (final module in PosModule.values) {
      if (module.legacyIndex == index) return module;
    }
    return null;
  }
}

/// Reactive source of truth for the active shell module.
final shellModuleProvider =
    StateProvider<PosModule>((ref) => PosModule.overview);

/// Collapsed/expanded state for the animated sidebar rail.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Selects a module and keeps the legacy [dashboardIndexProvider] in sync so
/// embedded feature screens continue to navigate correctly.
void selectModule(WidgetRef ref, PosModule module) {
  ref.read(shellModuleProvider.notifier).state = module;
  final legacy = module.legacyIndex;
  if (legacy != null) {
    ref.read(dashboardIndexProvider.notifier).state = legacy;
  }
}
