import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';
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
  final String email;
  final String phone;
  final String cnic; // Pakistani CNIC number
  final String joinDate;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.weeklyHours,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    this.email = '',
    this.phone = '',
    this.cnic = '',
    this.joinDate = '',
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
    String? email,
    String? phone,
    String? cnic,
    String? joinDate,
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
        email: email ?? this.email,
        phone: phone ?? this.phone,
        cnic: cnic ?? this.cnic,
        joinDate: joinDate ?? this.joinDate,
      );
}

class PayrollNotifier extends StateNotifier<List<Employee>> {
  PayrollNotifier() : super(const []) {
    _load();
  }

  final _db = DbService.instance;

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

  Employee _fromRow(Map<String, String?> r) {
    final raw = r['deductions'];
    final List deds = (raw == null || raw.isEmpty)
        ? const []
        : (jsonDecode(raw) as List);
    return Employee(
      id: r['id'] ?? '',
      name: r['name'] ?? '',
      role: r['role'] ?? '',
      status: StaffStatus.values.firstWhere((s) => s.name == r['status'],
          orElse: () => StaffStatus.offDuty),
      weeklyHours: double.tryParse(r['weekly_hours'] ?? '') ?? 0,
      basicSalary: double.tryParse(r['basic_salary'] ?? '') ?? 0,
      allowances: double.tryParse(r['allowances'] ?? '') ?? 0,
      email: r['email'] ?? '',
      phone: r['phone'] ?? '',
      cnic: r['cnic'] ?? '',
      joinDate: r['join_date'] ?? '',
      deductions: [
        for (final d in deds)
          PayDeduction(
              d['label'] as String, (d['amount'] as num).toDouble()),
      ],
    );
  }

  Future<void> _load() async {
    if (!_db.isConnected) {
      state = _seed;
      return;
    }
    final rows = await _db.rows('SELECT * FROM employees ORDER BY id');
    if (rows.isEmpty) {
      for (final e in _seed) {
        await _upsert(e);
      }
      state = _seed;
    } else {
      state = rows.map(_fromRow).toList();
      for (final e in state) {
        final n = int.tryParse(e.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (n != null && n > _seq) _seq = n;
      }
    }
  }

  Future<void> _upsert(Employee e) {
    final deds = jsonEncode(
        e.deductions.map((d) => {'label': d.label, 'amount': d.amount}).toList());
    return _db.exec(
      'INSERT INTO employees (id,name,role,status,weekly_hours,basic_salary,allowances,deductions,email,phone,cnic,join_date) '
      'VALUES (:id,:name,:role,:status,:wh,:salary,:allow,:deds,:email,:phone,:cnic,:jd) '
      'ON DUPLICATE KEY UPDATE name=:name, role=:role, status=:status, '
      'weekly_hours=:wh, basic_salary=:salary, allowances=:allow, deductions=:deds, '
      'email=:email, phone=:phone, cnic=:cnic, join_date=:jd',
      {
        'id': e.id,
        'name': e.name,
        'role': e.role,
        'status': e.status.name,
        'wh': e.weeklyHours,
        'salary': e.basicSalary,
        'allow': e.allowances,
        'deds': deds,
        'email': e.email,
        'phone': e.phone,
        'cnic': e.cnic,
        'jd': e.joinDate,
      },
    );
  }

  void setStatus(String id, StaffStatus status) {
    Employee? changed;
    state = [
      for (final e in state)
        if (e.id == id) (changed = e.copyWith(status: status)) else e,
    ];
    if (changed != null) _upsert(changed);
  }

  /// Hire a new employee. Income tax / provident fund deductions are auto-
  /// estimated (10% tax, 5% PF) so net pay is realistic out of the box.
  Employee add({
    required String name,
    required String role,
    required double basicSalary,
    double allowances = 0,
    String email = '',
    String phone = '',
    String cnic = '',
    String joinDate = '',
  }) {
    final e = Employee(
      id: 'EMP-${++_seq}',
      name: name.trim(),
      role: role,
      status: StaffStatus.offDuty,
      weeklyHours: 0,
      basicSalary: basicSalary,
      allowances: allowances,
      email: email.trim(),
      phone: phone.trim(),
      cnic: cnic.trim(),
      joinDate: joinDate.trim(),
      deductions: [
        PayDeduction('Income Tax', (basicSalary * 0.10).roundToDouble()),
        PayDeduction('Provident Fund', (basicSalary * 0.05).roundToDouble()),
      ],
    );
    state = [...state, e];
    _upsert(e);
    return e;
  }

  void update(String id,
      {String? name,
      String? role,
      double? basicSalary,
      double? allowances,
      String? email,
      String? phone,
      String? cnic,
      String? joinDate}) {
    Employee? changed;
    state = [
      for (final e in state)
        if (e.id == id)
          (changed = e.copyWith(
              name: name,
              role: role,
              basicSalary: basicSalary,
              allowances: allowances,
              email: email,
              phone: phone,
              cnic: cnic,
              joinDate: joinDate,
              deductions: basicSalary == null
                  ? null
                  : [
                      PayDeduction(
                          'Income Tax', (basicSalary * 0.10).roundToDouble()),
                      PayDeduction('Provident Fund',
                          (basicSalary * 0.05).roundToDouble()),
                    ]))
        else
          e,
    ];
    if (changed != null) _upsert(changed);
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _db.exec('DELETE FROM employees WHERE id=:id', {'id': id});
  }
}

final payrollProvider =
    StateNotifierProvider<PayrollNotifier, List<Employee>>(
        (ref) => PayrollNotifier());

final staffRoleFilterProvider = StateProvider<String>((ref) => 'All Roles');
