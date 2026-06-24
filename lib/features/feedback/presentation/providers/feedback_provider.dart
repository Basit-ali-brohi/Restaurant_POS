import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';

class Review {
  final String id;
  final String customer;
  final int rating; // 1..5
  final String comment;
  final String channel;
  final int daysAgo;
  final bool resolved;

  const Review({
    required this.id,
    required this.customer,
    required this.rating,
    required this.comment,
    required this.channel,
    required this.daysAgo,
    this.resolved = false,
  });

  bool get isComplaint => rating <= 2;

  Review copyWith({bool? resolved}) => Review(
        id: id,
        customer: customer,
        rating: rating,
        comment: comment,
        channel: channel,
        daysAgo: daysAgo,
        resolved: resolved ?? this.resolved,
      );
}

class ReviewsNotifier extends StateNotifier<List<Review>> {
  ReviewsNotifier() : super(_seed) {
    _load();
  }

  final _db = DbService.instance;

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final rows = await _db.rows('SELECT * FROM feedback ORDER BY days_ago');
    if (rows.isEmpty) {
      for (final r in _seed) {
        await _persist(r);
      }
    } else {
      state = [
        for (final r in rows)
          Review(
            id: r['id'] ?? '',
            customer: r['customer'] ?? '',
            rating: int.tryParse(r['rating'] ?? '') ?? 5,
            comment: r['comment'] ?? '',
            channel: r['channel'] ?? '',
            daysAgo: int.tryParse(r['days_ago'] ?? '') ?? 0,
            resolved: (r['resolved'] ?? '0') == '1',
          ),
      ];
    }
  }

  Future<void> _persist(Review r) => _db.exec(
        'INSERT INTO feedback (id,customer,rating,comment,channel,days_ago,resolved) '
        'VALUES (:id,:cust,:rate,:com,:ch,:days,:res) '
        'ON DUPLICATE KEY UPDATE resolved=:res',
        {
          'id': r.id,
          'cust': r.customer,
          'rate': r.rating,
          'com': r.comment,
          'ch': r.channel,
          'days': r.daysAgo,
          'res': r.resolved ? 1 : 0,
        },
      );

  static const List<Review> _seed = [
    Review(id: 'F-1', customer: 'Ayesha K.', rating: 5, comment: 'Saffron risotto was perfect. Impeccable service.', channel: 'QR Table', daysAgo: 0),
    Review(id: 'F-2', customer: 'Daniel R.', rating: 4, comment: 'Great food, slightly slow on drinks.', channel: 'Web', daysAgo: 0),
    Review(id: 'F-3', customer: 'Anonymous', rating: 2, comment: 'Order arrived cold via delivery.', channel: 'Foodpanda', daysAgo: 1),
    Review(id: 'F-4', customer: 'Sara M.', rating: 5, comment: 'Best Wagyu in town. Will return.', channel: 'QR Table', daysAgo: 1),
    Review(id: 'F-5', customer: 'Omar F.', rating: 1, comment: 'Wrong items delivered, no response on call.', channel: 'Careem', daysAgo: 2),
    Review(id: 'F-6', customer: 'Helena P.', rating: 4, comment: 'Lovely ambiance, fair pricing.', channel: 'Web', daysAgo: 3),
    Review(id: 'F-7', customer: 'Bilal A.', rating: 3, comment: 'Average experience, fries were soggy.', channel: 'QR Table', daysAgo: 4),
  ];

  void resolve(String id) {
    Review? changed;
    state = [
      for (final r in state)
        if (r.id == id) (changed = r.copyWith(resolved: true)) else r,
    ];
    if (changed != null) _persist(changed);
  }
}

final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, List<Review>>(
        (ref) => ReviewsNotifier());

final averageRatingProvider = Provider<double>((ref) {
  final list = ref.watch(reviewsProvider);
  if (list.isEmpty) return 0;
  return list.fold(0, (s, r) => s + r.rating) / list.length;
});

/// Count of reviews per star value (1..5).
final ratingDistributionProvider = Provider<Map<int, int>>((ref) {
  final list = ref.watch(reviewsProvider);
  final dist = {for (var i = 1; i <= 5; i++) i: 0};
  for (final r in list) {
    dist[r.rating] = (dist[r.rating] ?? 0) + 1;
  }
  return dist;
});
