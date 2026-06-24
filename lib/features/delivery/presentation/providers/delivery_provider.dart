import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Acquisition channels for incoming online orders.
enum OrderChannel {
  web('Web App', Icons.language, Color(0xFF6366F1)),
  foodpanda('Foodpanda', Icons.delivery_dining, Color(0xFFE3B041)),
  careem('Careem', Icons.directions_car, Color(0xFF10B981));

  const OrderChannel(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum OnlineStatus {
  incoming('Incoming', AppColors.info),
  accepted('Accepted', AppColors.accent),
  preparing('Preparing', Color(0xFFF59E0B)),
  dispatched('Dispatched', Color(0xFF8B5CF6)),
  delivered('Delivered', AppColors.success);

  const OnlineStatus(this.label, this.color);
  final String label;
  final Color color;

  OnlineStatus get next {
    final i = index;
    return i + 1 < OnlineStatus.values.length
        ? OnlineStatus.values[i + 1]
        : this;
  }
}

class OnlineOrder {
  final String id;
  final OrderChannel channel;
  final String customer;
  final String area;
  final int items;
  final double total;
  final OnlineStatus status;
  final int minsAgo;
  final String? riderId;

  const OnlineOrder({
    required this.id,
    required this.channel,
    required this.customer,
    required this.area,
    required this.items,
    required this.total,
    required this.status,
    required this.minsAgo,
    this.riderId,
  });

  OnlineOrder copyWith({OnlineStatus? status, String? riderId}) => OnlineOrder(
        id: id,
        channel: channel,
        customer: customer,
        area: area,
        items: items,
        total: total,
        status: status ?? this.status,
        minsAgo: minsAgo,
        riderId: riderId ?? this.riderId,
      );
}

class OnlineOrdersNotifier extends StateNotifier<List<OnlineOrder>> {
  OnlineOrdersNotifier() : super(_seed);

  static const List<OnlineOrder> _seed = [
    OnlineOrder(id: 'W-5012', channel: OrderChannel.web, customer: 'Ayesha K.', area: 'Gulberg', items: 3, total: 42.50, status: OnlineStatus.incoming, minsAgo: 1),
    OnlineOrder(id: 'FP-8841', channel: OrderChannel.foodpanda, customer: 'Daniel R.', area: 'DHA Phase 5', items: 2, total: 28.00, status: OnlineStatus.preparing, minsAgo: 9, riderId: 'D-02'),
    OnlineOrder(id: 'CR-3320', channel: OrderChannel.careem, customer: 'Sara M.', area: 'Model Town', items: 5, total: 76.20, status: OnlineStatus.dispatched, minsAgo: 18, riderId: 'D-01'),
    OnlineOrder(id: 'W-5009', channel: OrderChannel.web, customer: 'Omar F.', area: 'Johar Town', items: 1, total: 14.00, status: OnlineStatus.incoming, minsAgo: 2),
    OnlineOrder(id: 'FP-8830', channel: OrderChannel.foodpanda, customer: 'Helena P.', area: 'Cantt', items: 4, total: 58.90, status: OnlineStatus.delivered, minsAgo: 34, riderId: 'D-03'),
  ];

  void advance(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: o.status.next) else o,
    ];
  }

  void assignRider(String id, String riderId) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(riderId: riderId) else o,
    ];
  }

  /// Demo helper: injects a fresh random incoming order from an aggregator.
  void addSimulated() {
    const names = ['Bilal A.', 'Sana K.', 'Usman R.', 'Hina S.', 'Ali M.'];
    const areas = ['Gulberg', 'DHA Phase 2', 'Bahria Town', 'Clifton', 'Johar Town'];
    final rnd = DateTime.now().millisecondsSinceEpoch;
    final channel = OrderChannel.values[rnd % OrderChannel.values.length];
    final prefix = channel == OrderChannel.web
        ? 'W'
        : channel == OrderChannel.foodpanda
            ? 'FP'
            : 'CR';
    final order = OnlineOrder(
      id: '$prefix-${5000 + rnd % 5000}',
      channel: channel,
      customer: names[rnd % names.length],
      area: areas[(rnd ~/ 7) % areas.length],
      items: 1 + rnd % 5,
      total: 10.0 + rnd % 80,
      status: OnlineStatus.incoming,
      minsAgo: 0,
    );
    state = [order, ...state];
  }
}

final onlineOrdersProvider =
    StateNotifierProvider<OnlineOrdersNotifier, List<OnlineOrder>>(
        (ref) => OnlineOrdersNotifier());

/// A delivery rider with a live (mock) trip progress index.
class Rider {
  final String id;
  final String name;
  final String zone;
  final bool onTrip;
  final int activeTrips;
  final int completedToday;
  final double commission;
  final double progress; // 0..1 mock coordinate progress

  const Rider({
    required this.id,
    required this.name,
    required this.zone,
    required this.onTrip,
    required this.activeTrips,
    required this.completedToday,
    required this.commission,
    required this.progress,
  });
}

class RidersNotifier extends StateNotifier<List<Rider>> {
  RidersNotifier() : super(_seed) {
    _load();
  }

  final _db = DbService.instance;
  int _seq = 4;

  static const List<Rider> _seed = [
    Rider(id: 'D-01', name: 'Imran Ali', zone: 'Zone A · Model Town', onTrip: true, activeTrips: 1, completedToday: 12, commission: 1840, progress: 0.72),
    Rider(id: 'D-02', name: 'Faisal Khan', zone: 'Zone B · DHA', onTrip: true, activeTrips: 1, completedToday: 9, commission: 1360, progress: 0.35),
    Rider(id: 'D-03', name: 'Naveed Iqbal', zone: 'Zone C · Cantt', onTrip: false, activeTrips: 0, completedToday: 15, commission: 2210, progress: 1.0),
    Rider(id: 'D-04', name: 'Zara Sheikh', zone: 'Zone A · Gulberg', onTrip: false, activeTrips: 0, completedToday: 7, commission: 980, progress: 0.0),
  ];

  Rider _fromRow(Map<String, String?> r) => Rider(
        id: r['id'] ?? '',
        name: r['name'] ?? '',
        zone: r['zone'] ?? '',
        onTrip: (r['on_trip'] ?? '0') == '1',
        activeTrips: int.tryParse(r['active_trips'] ?? '') ?? 0,
        completedToday: int.tryParse(r['completed_today'] ?? '') ?? 0,
        commission: double.tryParse(r['commission'] ?? '') ?? 0,
        progress: double.tryParse(r['progress'] ?? '') ?? 0,
      );

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows = await _db.rows('SELECT * FROM riders ORDER BY id');
    if (rows.isEmpty) {
      for (final r in _seed) {
        await _persist(r);
      }
    } else {
      state = rows.map(_fromRow).toList();
      for (final r in state) {
        final n = int.tryParse(r.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (n != null && n > _seq) _seq = n;
      }
    }
  }

  Future<void> _persist(Rider r) => _db.exec(
        'INSERT INTO riders (id,name,zone,on_trip,active_trips,completed_today,commission,progress) '
        'VALUES (:id,:name,:zone,:trip,:active,:done,:comm,:prog) '
        'ON DUPLICATE KEY UPDATE name=:name, zone=:zone, on_trip=:trip, '
        'active_trips=:active, completed_today=:done, commission=:comm, progress=:prog',
        {
          'id': r.id,
          'name': r.name,
          'zone': r.zone,
          'trip': r.onTrip ? 1 : 0,
          'active': r.activeTrips,
          'done': r.completedToday,
          'comm': r.commission,
          'prog': r.progress,
        },
      );

  void add({required String name, required String zone}) {
    final rider = Rider(
      id: 'D-${(++_seq).toString().padLeft(2, '0')}',
      name: name.trim(),
      zone: zone.trim(),
      onTrip: false,
      activeTrips: 0,
      completedToday: 0,
      commission: 0,
      progress: 0,
    );
    state = [...state, rider];
    _persist(rider);
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _db.exec('DELETE FROM riders WHERE id=:id', {'id': id});
  }
}

final ridersProvider =
    StateNotifierProvider<RidersNotifier, List<Rider>>(
        (ref) => RidersNotifier());
