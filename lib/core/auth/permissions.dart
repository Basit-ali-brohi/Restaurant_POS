import '../providers/navigation_provider.dart';

/// SRS 3.x — Role-Based Access Control.
///
/// Maps each staff role to the set of [PosModule]s it may open. The Manager
/// role is treated as a super-user with access to every module. Anything not
/// listed for a role is hidden from the sidebar and blocked by the shell guard.
class Permissions {
  Permissions._();

  /// Modules every signed-in role can always reach.
  static const Set<PosModule> _common = {
    PosModule.overview,
    PosModule.notifications,
  };

  /// Per-role module grants (Manager handled separately as super-user).
  static const Map<String, Set<PosModule>> _byRole = {
    'Floor Manager': {
      PosModule.pos,
      PosModule.floor,
      PosModule.kitchen,
      PosModule.inventory,
      PosModule.menu,
      PosModule.crm,
      PosModule.onlineOrders,
      PosModule.delivery,
      PosModule.feedback,
      PosModule.insights,
      PosModule.suppliers,
      PosModule.purchasing,
      PosModule.reservations,
      PosModule.staff,
      PosModule.history,
      PosModule.sales,
      PosModule.shift,
      PosModule.settings,
    },
    'Head Chef': {
      PosModule.floor,
      PosModule.kitchen,
      PosModule.inventory,
      PosModule.menu,
      PosModule.recipeCosting,
      PosModule.suppliers,
      PosModule.purchasing,
      PosModule.history,
    },
    'Server': {
      PosModule.pos,
      PosModule.floor,
      PosModule.kitchen,
      PosModule.reservations,
      PosModule.history,
    },
    'Bartender': {
      PosModule.pos,
      PosModule.floor,
      PosModule.kitchen,
      PosModule.history,
    },
  };

  /// Whether [role] has super-user (Manager/Admin) access.
  static bool isManager(String role) =>
      role == 'Manager' || role == 'Admin' || role == 'Owner';

  /// Can [role] open [module]?
  static bool canAccess(String role, PosModule module) {
    if (isManager(role)) return true;
    if (_common.contains(module)) return true;
    return _byRole[role]?.contains(module) ?? false;
  }

  /// The modules of [group] that [role] is allowed to see, in declaration order.
  static List<PosModule> visibleInGroup(String role, ModuleGroup group) {
    return PosModule.inGroup(group)
        .where((m) => canAccess(role, m))
        .toList(growable: false);
  }
}
