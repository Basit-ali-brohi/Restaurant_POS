import 'package:flutter_riverpod/legacy.dart';

/// A staff member who can sign in to the terminal via a quick PIN.
class StaffMember {
  final String name;
  final String role;
  final String pin;
  const StaffMember(this.name, this.role, this.pin);

  String get initials => name.isNotEmpty ? name[0] : '?';
}

/// Demo roster for the PIN quick-switch (terminal stays logged in; staff swap
/// fast during service without re-entering email/password).
const List<StaffMember> kStaffMembers = [
  StaffMember('Admin', 'Manager', '0000'),
  StaffMember('Marcus Vance', 'Head Chef', '1042'),
  StaffMember('Sarah Jenkins', 'Floor Manager', '1112'),
  StaffMember('David Chen', 'Server', '1088'),
  StaffMember('Elena Rostova', 'Bartender', '1108'),
];

/// The staff member currently operating the terminal.
final activeUserProvider =
    StateProvider<StaffMember>((ref) => kStaffMembers.first);
