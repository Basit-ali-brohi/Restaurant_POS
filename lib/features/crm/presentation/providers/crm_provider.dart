import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
      );
}

class CustomersNotifier extends StateNotifier<List<Customer>> {
  CustomersNotifier() : super(_seed);

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

  void addPoints(String id, int delta) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(points: (c.points + delta).clamp(0, 1 << 31)) else c,
    ];
  }

  /// Create a new member. New customers default to the "New" segment.
  Customer add({
    required String name,
    required String phone,
    required String email,
    int points = 0,
  }) {
    final c = Customer(
      id: 'C-${(++_seq).toString().padLeft(3, '0')}',
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      points: points,
      lifetimeSpend: 0,
      visits: 0,
      lastVisitDays: 0,
      segment: CustomerSegment.newcomer,
    );
    state = [c, ...state];
    return c;
  }

  void update(String id,
      {String? name,
      String? phone,
      String? email,
      CustomerSegment? segment}) {
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(name: name, phone: phone, email: email, segment: segment)
        else
          c,
    ];
  }

  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();
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
