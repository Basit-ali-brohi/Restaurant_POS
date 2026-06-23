import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Loyalty tiers earned by lifetime points.
enum LoyaltyTier {
  bronze('Bronze', 0, Color(0xFFB08D57)),
  silver('Silver', 1000, Color(0xFF9CA3AF)),
  gold('Gold', 3000, Color(0xFFE3B041)),
  platinum('Platinum', 7000, Color(0xFF7C8AA5));

  const LoyaltyTier(this.label, this.minPoints, this.color);
  final String label;
  final int minPoints;
  final Color color;

  static LoyaltyTier forPoints(int points) {
    LoyaltyTier tier = LoyaltyTier.bronze;
    for (final t in LoyaltyTier.values) {
      if (points >= t.minPoints) tier = t;
    }
    return tier;
  }
}

/// Behavioural segment used for marketing targeting.
enum CustomerSegment {
  vip('VIP', AppColors.accent),
  regular('Regular', AppColors.info),
  newcomer('New', AppColors.success),
  atRisk('At Risk', AppColors.error);

  const CustomerSegment(this.label, this.color);
  final String label;
  final Color color;
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int points;
  final double lifetimeSpend;
  final int visits;
  final int lastVisitDays;
  final CustomerSegment segment;
  final String address;
  final String city;
  final String dob; // date of birth (yyyy-MM-dd or free text)

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.points,
    required this.lifetimeSpend,
    required this.visits,
    required this.lastVisitDays,
    required this.segment,
    this.address = '',
    this.city = '',
    this.dob = '',
  });

  LoyaltyTier get tier => LoyaltyTier.forPoints(points);

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    int? points,
    double? lifetimeSpend,
    int? visits,
    int? lastVisitDays,
    CustomerSegment? segment,
    String? address,
    String? city,
    String? dob,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        points: points ?? this.points,
        lifetimeSpend: lifetimeSpend ?? this.lifetimeSpend,
        visits: visits ?? this.visits,
        lastVisitDays: lastVisitDays ?? this.lastVisitDays,
        segment: segment ?? this.segment,
        address: address ?? this.address,
        city: city ?? this.city,
        dob: dob ?? this.dob,
      );
}

class CustomersNotifier extends StateNotifier<List<Customer>> {
  CustomersNotifier() : super(const []) {
    _load();
  }

  final _db = DbService.instance;

  static const List<Customer> _seed = [
    Customer(
        id: 'C-001',
        name: 'Ayesha Khan',
        phone: '+92 300 1234567',
        email: 'ayesha.k@mail.com',
        points: 8420,
        lifetimeSpend: 124300,
        visits: 86,
        lastVisitDays: 1,
        segment: CustomerSegment.vip),
    Customer(
        id: 'C-002',
        name: 'Daniel Rossi',
        phone: '+92 301 9988776',
        email: 'd.rossi@mail.com',
        points: 3120,
        lifetimeSpend: 58200,
        visits: 41,
        lastVisitDays: 4,
        segment: CustomerSegment.regular),
    Customer(
        id: 'C-003',
        name: 'Sara Mehta',
        phone: '+92 333 4567890',
        email: 'sara.mehta@mail.com',
        points: 1240,
        lifetimeSpend: 22900,
        visits: 18,
        lastVisitDays: 2,
        segment: CustomerSegment.regular),
    Customer(
        id: 'C-004',
        name: 'Omar Farooq',
        phone: '+92 345 1112223',
        email: 'omar.f@mail.com',
        points: 320,
        lifetimeSpend: 4100,
        visits: 3,
        lastVisitDays: 1,
        segment: CustomerSegment.newcomer),
    Customer(
        id: 'C-005',
        name: 'Helena Park',
        phone: '+92 322 7654321',
        email: 'h.park@mail.com',
        points: 5600,
        lifetimeSpend: 91500,
        visits: 63,
        lastVisitDays: 47,
        segment: CustomerSegment.atRisk),
    Customer(
        id: 'C-006',
        name: 'Bilal Ahmed',
        phone: '+92 311 5559990',
        email: 'bilal.a@mail.com',
        points: 2050,
        lifetimeSpend: 37800,
        visits: 29,
        lastVisitDays: 6,
        segment: CustomerSegment.regular),
  ];

  int _seq = 6;

  Customer _fromRow(Map<String, String?> r) => Customer(
        id: r['id'] ?? '',
        name: r['name'] ?? '',
        phone: r['phone'] ?? '',
        email: r['email'] ?? '',
        points: int.tryParse(r['points'] ?? '') ?? 0,
        lifetimeSpend: double.tryParse(r['lifetime_spend'] ?? '') ?? 0,
        visits: int.tryParse(r['visits'] ?? '') ?? 0,
        lastVisitDays: int.tryParse(r['last_visit_days'] ?? '') ?? 0,
        segment: CustomerSegment.values.firstWhere(
            (s) => s.name == r['segment'],
            orElse: () => CustomerSegment.regular),
        address: r['address'] ?? '',
        city: r['city'] ?? '',
        dob: r['dob'] ?? '',
      );

  Future<void> _load() async {
    if (!_db.isConnected) {
      state = _seed;
      return;
    }
    final rows = await _db.rows('SELECT * FROM customers ORDER BY id');
    if (rows.isEmpty) {
      for (final c in _seed) {
        await _upsert(c);
      }
      state = _seed;
    } else {
      state = rows.map(_fromRow).toList();
      // Track the highest C-NNN id so new members don't collide.
      for (final c in state) {
        final n = int.tryParse(c.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (n != null && n > _seq) _seq = n;
      }
    }
  }

  Future<void> _upsert(Customer c) => _db.exec(
        'INSERT INTO customers (id,name,phone,email,points,lifetime_spend,visits,last_visit_days,segment,address,city,dob) '
        'VALUES (:id,:name,:phone,:email,:points,:spend,:visits,:lvd,:seg,:addr,:city,:dob) '
        'ON DUPLICATE KEY UPDATE name=:name, phone=:phone, email=:email, points=:points, '
        'lifetime_spend=:spend, visits=:visits, last_visit_days=:lvd, segment=:seg, '
        'address=:addr, city=:city, dob=:dob',
        {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'email': c.email,
          'points': c.points,
          'spend': c.lifetimeSpend,
          'visits': c.visits,
          'lvd': c.lastVisitDays,
          'seg': c.segment.name,
          'addr': c.address,
          'city': c.city,
          'dob': c.dob,
        },
      );

  void addPoints(String id, int delta) {
    Customer? changed;
    state = [
      for (final c in state)
        if (c.id == id)
          (changed = c.copyWith(points: (c.points + delta).clamp(0, 1 << 31)))
        else
          c,
    ];
    if (changed != null) _upsert(changed);
  }

  /// Create a new member. New customers default to the "New" segment.
  Customer add({
    required String name,
    required String phone,
    required String email,
    String address = '',
    String city = '',
    String dob = '',
    int points = 0,
  }) {
    final c = Customer(
      id: 'C-${(++_seq).toString().padLeft(3, '0')}',
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      address: address.trim(),
      city: city.trim(),
      dob: dob.trim(),
      points: points,
      lifetimeSpend: 0,
      visits: 0,
      lastVisitDays: 0,
      segment: CustomerSegment.newcomer,
    );
    state = [c, ...state];
    _upsert(c);
    return c;
  }

  void update(String id,
      {String? name,
      String? phone,
      String? email,
      CustomerSegment? segment,
      String? address,
      String? city,
      String? dob}) {
    Customer? changed;
    state = [
      for (final c in state)
        if (c.id == id)
          (changed = c.copyWith(
              name: name,
              phone: phone,
              email: email,
              segment: segment,
              address: address,
              city: city,
              dob: dob))
        else
          c,
    ];
    if (changed != null) _upsert(changed);
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    _db.exec('DELETE FROM customers WHERE id=:id', {'id': id});
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, List<Customer>>(
        (ref) => CustomersNotifier());

final crmSegmentFilterProvider = StateProvider<CustomerSegment?>((ref) => null);

class MarketingCampaign {
  final String id;
  final String name;
  final String channel;
  final String audience;
  final String reward;
  final bool active;

  const MarketingCampaign({
    required this.id,
    required this.name,
    required this.channel,
    required this.audience,
    required this.reward,
    required this.active,
  });
}

final campaignsProvider = Provider<List<MarketingCampaign>>((ref) {
  return const [
    MarketingCampaign(
        id: 'M-1',
        name: 'Weekend Double Points',
        channel: 'Push + SMS',
        audience: 'All members',
        reward: '2× points',
        active: true),
    MarketingCampaign(
        id: 'M-2',
        name: 'Win-back VIPs',
        channel: 'Email',
        audience: 'At Risk',
        reward: '500 bonus pts',
        active: true),
    MarketingCampaign(
        id: 'M-3',
        name: 'Gold Tier Tasting',
        channel: 'Email',
        audience: 'Gold & Platinum',
        reward: 'Free pairing',
        active: false),
  ];
});
