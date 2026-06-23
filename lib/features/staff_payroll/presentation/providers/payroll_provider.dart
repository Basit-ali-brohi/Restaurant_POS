import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/theme/app_colors.dart';

/// Live clock status of a staff member.
enum StaffStatus {
  clockedIn('Clocked In', AppColors.success),
  onBreak('On Break', AppColors.warning),
  offDuty('Off Duty', Color(0xFF94A3B8));

  const StaffStatus(this.label, this.color);
  final String label;
  final Color color;
}

class PayDeduction {
  final String label;
  final double amount;
  const PayDeduction(this.label, this.amount);
}

class Employee {
  final String id;
  final String name;
  final String role;
  final StaffStatus status;
  final double weeklyHours;
  final double basicSalary; // monthly
  final double allowances;
  final List<PayDeduction> deductions;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.weeklyHours,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
  });

  double get totalDeductions =>
      deductions.fold(0.0, (s, d) => s + d.amount);
  double get netPay => basicSalary + allowances - totalDeductions;
  String get initials => name.isNotEmpty ? name[0] : '?';

  Employee copyWith({
    String? name,
    String? role,
    StaffStatus? status,
    double? weeklyHours,
    double? basicSalary,
    double? allowances,
    List<PayDeduction>? deductions,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        status: status ?? this.status,
        weeklyHours: weeklyHours ?? this.weeklyHours,
        basicSalary: basicSalary ?? this.basicSalary,
        allowances: allowances ?? this.allowances,
        deductions: deductions ?? this.deductions,
      );
}

class PayrollNotifier extends StateNotifier<List<Employee>> {
  PayrollNotifier() : super(_seed);

  static const List<Employee> _seed = [
    Employee(
        id: 'EMP-042',
        name: 'Marcus Vance',
        role: 'Head Chef',
        status: StaffStatus.clockedIn,
        weeklyHours: 32.5,
        basicSalary: 145000,
        allowances: 18000,
        deductions: [
          PayDeduction('Income Tax', 14500),
          PayDeduction('Provident Fund', 7250),
          PayDeduction('Advance', 10000),
        ]),
    Employee(
        id: 'EMP-108',
        name: 'Elena Rostova',
        role: 'Bartender',
        status: StaffStatus.offDuty,
        weeklyHours: 24.0,
        basicSalary: 72000,
        allowances: 6000,
        deductions: [
          PayDeduction('Income Tax', 5400),
          PayDeduction('Provident Fund', 3600),
        ]),
    Employee(
        id: 'EMP-088',
        name: 'David Chen',
        role: 'Server',
        status: StaffStatus.onBreak,
        weeklyHours: 18.5,
        basicSalary: 58000,
        allowances: 4000,
        deductions: [
          PayDeduction('Income Tax', 3500),
          PayDeduction('Absences (1d)', 2200),
        ]),
    Employee(
        id: 'EMP-112',
        name: 'Sarah Jenkins',
        role: 'Floor Manager',
        status: StaffStatus.clockedIn,
        weeklyHours: 40.0,
        basicSalary: 110000,
        allowances: 12000,
        deductions: [
          PayDeduction('Income Tax', 11000),
          PayDeduction('Provident Fund', 5500),
        ]),
    Employee(
        id: 'EMP-056',
        name: 'Anita Patel',
        role: 'Sous Chef',
        status: StaffStatus.offDuty,
        weeklyHours: 38.0,
        basicSalary: 96000,
        allowances: 9000,
        deductions: [
          PayDeduction('Income Tax', 8600),
          PayDeduction('Provident Fund', 4800),
        ]),
  ];

  int _seq = 200;

  /// Standard roles offered when hiring.
  static const List<String> roles = [
    'Head Chef',
    'Sous Chef',
    'Server',
    'Bartender',
    'Floor Manager',
    'Cashier',
    'Cleaner',
  ];

  void setStatus(String id, StaffStatus status) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(status: status) else e,
    ];
  }

  /// Hire a new employee. Income tax / provident fund deductions are auto-
  /// estimated (10% tax, 5% PF) so net pay is realistic out of the box.
  Employee add({
    required String name,
    required String role,
    required double basicSalary,
    double allowances = 0,
  }) {
    final e = Employee(
      id: 'EMP-${++_seq}',
      name: name.trim(),
      role: role,
      status: StaffStatus.offDuty,
      weeklyHours: 0,
      basicSalary: basicSalary,
      allowances: allowances,
      deductions: [
        PayDeduction('Income Tax', (basicSalary * 0.10).roundToDouble()),
        PayDeduction('Provident Fund', (basicSalary * 0.05).roundToDouble()),
      ],
    );
    state = [...state, e];
    return e;
  }

  void update(String id,
      {String? name, String? role, double? basicSalary, double? allowances}) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(
              name: name,
              role: role,
              basicSalary: basicSalary,
              allowances: allowances,
              deductions: basicSalary == null
                  ? null
                  : [
                      PayDeduction(
                          'Income Tax', (basicSalary * 0.10).roundToDouble()),
                      PayDeduction('Provident Fund',
                          (basicSalary * 0.05).roundToDouble()),
                    ])
        else
          e,
    ];
  }

  void remove(String id) =>
      state = state.where((e) => e.id != id).toList();
}

final payrollProvider =
    StateNotifierProvider<PayrollNotifier, List<Employee>>(
        (ref) => PayrollNotifier());

final staffRoleFilterProvider = StateProvider<String>((ref) => 'All Roles');
