// =============================================================================
// APP SHELL — Premium "Obsidian & Gold" global chrome
// -----------------------------------------------------------------------------
// Aligned to the project's established architecture:
//   • State        : Riverpod (themeProvider, shellModuleProvider, dashboard…)
//   • Design tokens : AppColors (Slate + Amber-Gold) with fluid light/dark
//   • Geometry      : desktop-first, uniform BorderRadius.circular(8.0)
// Wires the five operational modules to their real feature screens, leaving the
// Dashboard Overview as a cleanly-labelled wrapper to grow in later steps.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_tones.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../auth/permissions.dart';
import '../../features/audit/presentation/providers/audit_provider.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/widgets/pin_switch_sheet.dart';
import '../../features/notifications/presentation/widgets/notification_center.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/table_management/presentation/screens/floor_monitor_screen.dart';
import '../../features/kitchen/presentation/screens/kds_screen.dart';
import '../../features/inventory/presentation/screens/stock_control_screen.dart';
import '../../features/inventory/presentation/screens/suppliers_screen.dart';
import '../../features/purchasing/presentation/screens/purchasing_screen.dart';
import '../../features/recipes/presentation/screens/recipe_costing_screen.dart';
import '../../features/crm/presentation/screens/crm_screen.dart';
import '../../features/delivery/presentation/screens/online_orders_screen.dart';
import '../../features/delivery/presentation/screens/delivery_hub_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/staff_payroll/presentation/screens/staff_payroll_screen.dart';
import '../../features/branches/presentation/screens/multi_branch_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/finance/presentation/screens/sales_transactions_screen.dart';
import '../../features/tax/presentation/screens/tax_settings_screen.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../features/insights/presentation/screens/business_insights_screen.dart';
import '../../features/menu/presentation/screens/menu_editor_screen.dart';
import '../../features/reservations/presentation/screens/reservations_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_overview_screen.dart';
import '../../features/dashboard/presentation/screens/orders_history_screen.dart';
import '../../features/dashboard/presentation/screens/shift_screen.dart';

/// Mandated uniform corner radius across every panel, card & field.
const double kShellRadius = 8.0;
const Duration kShellMotion = Duration(milliseconds: 320);
const Curve kShellCurve = Curves.easeOutCubic;

const double _kSidebarWidth = 256.0;
const double _kSidebarCollapsed = 80.0;
const double _kTopBarHeight = 80.0;

// =============================================================================
// ROOT SHELL
// =============================================================================

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  Widget _screenFor(PosModule module) {
    switch (module) {
      case PosModule.overview:
        return const DashboardOverviewScreen();
      case PosModule.pos:
        return const PosScreen();
      case PosModule.floor:
        return const FloorMonitorScreen();
      case PosModule.kitchen:
        return const KDSScreen();
      case PosModule.inventory:
        return const StockControlScreen();
      case PosModule.menu:
        return const MenuEditorScreen();
      case PosModule.recipeCosting:
        return const RecipeCostingScreen();
      case PosModule.crm:
        return const CrmScreen();
      case PosModule.onlineOrders:
        return const OnlineOrdersScreen();
      case PosModule.delivery:
        return const DeliveryHubScreen();
      case PosModule.feedback:
        return const FeedbackScreen();
      case PosModule.notifications:
        return const NotificationCenterScreen();
      case PosModule.branches:
        return const MultiBranchScreen();
      case PosModule.finance:
        return const FinanceScreen();
      case PosModule.tax:
        return const TaxSettingsScreen();
      case PosModule.audit:
        return const AuditLogScreen();
      case PosModule.insights:
        return const BusinessInsightsScreen();
      case PosModule.suppliers:
        return const SuppliersScreen();
      case PosModule.purchasing:
        return const PurchasingScreen();
      case PosModule.reservations:
        return const ReservationsScreen();
      case PosModule.staff:
        return const StaffPayrollScreen();
      case PosModule.history:
        return const OrdersHistoryScreen();
      case PosModule.sales:
        return const SalesTransactionsScreen();
      case PosModule.shift:
        return const ShiftScreen();
      case PosModule.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final t = AppTones(isDark);
    final module = ref.watch(shellModuleProvider);
    final role = ref.watch(activeUserProvider).role;

    // Bridge: if an embedded screen mutates the legacy dashboard index
    // (e.g. Tables -> Menu), follow it so the shell stays in sync.
    ref.listen<int>(dashboardIndexProvider, (_, next) {
      final mapped = PosModule.fromLegacyIndex(next);
      if (mapped != null && ref.read(shellModuleProvider) != mapped) {
        ref.read(shellModuleProvider.notifier).state = mapped;
      }
    });

    // RBAC guard: when staff swap to a role that can't see the active module,
    // bounce them back to the always-accessible Dashboard Overview. Every swap
    // is also written to the forensic audit trail (SRS 3.x).
    ref.listen<StaffMember>(activeUserProvider, (prev, next) {
      ref.read(auditTrailProvider.notifier).log(
            category: AuditCategory.security,
            action: 'Active user switched',
            detail: '${next.name} · ${next.role}'
                '${prev != null ? ' (from ${prev.name})' : ''}',
            actor: next.name,
          );
      final current = ref.read(shellModuleProvider);
      if (!Permissions.canAccess(next.role, current)) {
        ref.read(shellModuleProvider.notifier).state = PosModule.overview;
        ref.read(auditTrailProvider.notifier).log(
              category: AuditCategory.security,
              action: 'Access blocked',
              detail: '${next.role} denied "${current.label}" — redirected',
              actor: next.name,
            );
      }
    });

    final canView = Permissions.canAccess(role, module);

    return Scaffold(
      backgroundColor: t.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideBar(tones: t),
          Expanded(
            child: Column(
              children: [
                _TopBar(tones: t, module: module),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: kShellMotion,
                    switchInCurve: kShellCurve,
                    switchOutCurve: kShellCurve,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(canView ? module : null),
                      child: canView
                          ? _screenFor(module)
                          : _AccessDenied(tones: t, role: role),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RBAC — ACCESS DENIED
// =============================================================================

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.tones, required this.role});
  final AppTones tones;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tones.canvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_outline,
                  size: 30, color: AppColors.error),
            ),
            const SizedBox(height: 18),
            Text('Access Restricted',
                style: TextStyle(
                    color: tones.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            SizedBox(
              width: 360,
              child: Text(
                'Your role ($role) does not have permission to view this '
                'module. Contact a manager if you need access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tones.textMuted, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SIDEBAR
// =============================================================================

class _SideBar extends ConsumerWidget {
  const _SideBar({required this.tones});
  final AppTones tones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final active = ref.watch(shellModuleProvider);
    final role = ref.watch(activeUserProvider).role;
    final lowStock =
        ref.watch(inventoryProvider).where((i) => i.quantity <= 0).length;

    final operations =
        Permissions.visibleInGroup(role, ModuleGroup.operations);
    final management =
        Permissions.visibleInGroup(role, ModuleGroup.management);

    Widget tileFor(PosModule module) => _NavTile(
          tones: tones,
          module: module,
          selected: active == module,
          collapsed: collapsed,
          badge: module == PosModule.inventory ? lowStock : 0,
          onTap: () => selectModule(ref, module),
        );

    return AnimatedContainer(
      duration: kShellMotion,
      curve: kShellCurve,
      width: collapsed ? _kSidebarCollapsed : _kSidebarWidth,
      decoration: const BoxDecoration(
        color: AppTones.navBg,
        border: Border(right: BorderSide(color: AppTones.navBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Brand(tones: tones, collapsed: collapsed),
          const Divider(height: 1, color: AppTones.navBorder),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (operations.isNotEmpty)
                  _SectionLabel(
                      tones: tones, collapsed: collapsed, text: 'OPERATIONS'),
                for (final module in operations) tileFor(module),
                if (management.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SectionLabel(
                      tones: tones, collapsed: collapsed, text: 'MANAGEMENT'),
                  for (final module in management) tileFor(module),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTones.navBorder),
          _LogoutControl(tones: tones, collapsed: collapsed),
          _CollapseControl(tones: tones, collapsed: collapsed),
        ],
      ),
    );
  }
}

/// Uppercase section divider. Collapses to a thin rule when the rail is narrow.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
      {required this.tones, required this.collapsed, required this.text});
  final AppTones tones;
  final bool collapsed;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Divider(height: 1, color: AppTones.navBorder),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTones.navMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Sidebar footer action that returns to the login screen, mirroring the
/// retired dashboard's logout behaviour.
class _LogoutControl extends StatelessWidget {
  const _LogoutControl({required this.tones, required this.collapsed});
  final AppTones tones;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kShellRadius),
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(kShellRadius),
              border:
                  Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                const Icon(Icons.logout, size: 19, color: AppColors.error),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  const Text('Logout',
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.tones, required this.collapsed});
  final AppTones tones;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kTopBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kShellRadius),
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTones.gold.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white, size: 22),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CloudPOS',
                      style: TextStyle(
                        color: AppTones.navText,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      )),
                  const Text('PRO',
                      style: TextStyle(
                        color: AppTones.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 4.0,
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.tones,
    required this.module,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    this.badge = 0,
  });

  final AppTones tones;
  final PosModule module;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(module.icon,
            size: 21, color: selected ? AppTones.gold : AppTones.navMuted),
        if (badge > 0)
          Positioned(
            right: -6,
            top: -5,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTones.navBg, width: 1.5),
              ),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );

    final tile = AnimatedContainer(
      duration: kShellMotion,
      curve: kShellCurve,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppTones.gold.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(kShellRadius),
        border: Border.all(
          color: selected
              ? AppTones.gold.withValues(alpha: 0.40)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          icon,
          if (!collapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                module.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppTones.navText : AppTones.navMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTones.gold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kShellRadius),
        onTap: onTap,
        child: collapsed ? Tooltip(message: module.label, child: tile) : tile,
      ),
    );
  }
}

class _CollapseControl extends ConsumerWidget {
  const _CollapseControl({required this.tones, required this.collapsed});
  final AppTones tones;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kShellRadius),
          onTap: () => ref
              .read(sidebarCollapsedProvider.notifier)
              .update((v) => !v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTones.navAlt,
              borderRadius: BorderRadius.circular(kShellRadius),
              border: Border.all(color: AppTones.navBorder),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(collapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 20, color: AppTones.navMuted),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Text('Collapse',
                      style: TextStyle(
                          color: AppTones.navMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TOP BAR
// =============================================================================

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.tones, required this.module});
  final AppTones tones;
  final PosModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return Container(
      height: _kTopBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: tones.surface,
        border: Border(bottom: BorderSide(color: tones.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module.label,
                  style: TextStyle(
                    color: tones.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  )),
              const SizedBox(height: 2),
              Text(module.subtitle,
                  style: TextStyle(color: tones.textMuted, fontSize: 12.5)),
            ],
          ),
          const Spacer(),
          _ThemeToggle(tones: tones, isDark: isDark),
          const SizedBox(width: 14),
          const NotificationBell(),
          const SizedBox(width: 14),
          _UserChip(tones: tones),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({required this.tones, required this.isDark});
  final AppTones tones;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kShellRadius),
        onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        child: AnimatedContainer(
          duration: kShellMotion,
          curve: kShellCurve,
          width: 92,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tones.surfaceAlt,
            borderRadius: BorderRadius.circular(kShellRadius),
            border: Border.all(color: tones.border),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: kShellMotion,
                curve: kShellCurve,
                alignment:
                    isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTones.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(kShellRadius),
                    border: Border.all(
                        color: AppTones.gold.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.light_mode,
                      size: 18,
                      color: isDark ? tones.textMuted : AppTones.gold),
                  Icon(Icons.dark_mode,
                      size: 18,
                      color: isDark ? AppTones.gold : tones.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserChip extends ConsumerWidget {
  const _UserChip({required this.tones});
  final AppTones tones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProvider);
    return Tooltip(
      message: 'Switch user (PIN)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kShellRadius),
          onTap: () => PinSwitchSheet.show(context),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: tones.surfaceAlt,
              borderRadius: BorderRadius.circular(kShellRadius),
              border: Border.all(color: tones.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kShellRadius),
                    gradient: AppColors.goldGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(user.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: TextStyle(
                            color: tones.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(user.role,
                        style: TextStyle(color: tones.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.expand_more, size: 18, color: tones.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
