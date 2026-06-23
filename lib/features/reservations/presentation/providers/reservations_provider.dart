import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';

/// Lifecycle of a customer reservation.
enum ReservationStatus {
  pending('Pending', AppColors.warning),
  confirmed('Confirmed', AppColors.info),
  seated('Seated', AppColors.success),
  cancelled('Cancelled', AppColors.error);

  const ReservationStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Reservation {
  final String id;
  final String guestName;
  final String phone;
  final int partySize;
  final DateTime time;
  final String? tableName;
  final ReservationStatus status;
  final String? note;

  const Reservation({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.partySize,
    required this.time,
    this.tableName,
    this.status = ReservationStatus.pending,
    this.note,
  });

  Reservation copyWith({ReservationStatus? status, String? tableName}) {
    return Reservation(
      id: id,
      guestName: guestName,
      phone: phone,
      partySize: partySize,
      time: time,
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
      note: note,
    );
  }
}

class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier() : super(_seed());

  static List<Reservation> _seed() {
    final now = DateTime.now();
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    return [
      Reservation(
          id: 'r1',
          guestName: 'Ayesha Khan',
          phone: '+92 300 1234567',
          partySize: 4,
          time: at(19, 0),
          tableName: 'G12',
          status: ReservationStatus.confirmed,
          note: 'Window seat preferred'),
      Reservation(
          id: 'r2',
          guestName: 'Daniel Rossi',
          phone: '+92 301 9988776',
          partySize: 2,
          time: at(20, 30),
          status: ReservationStatus.pending),
      Reservation(
          id: 'r3',
          guestName: 'The Mehtas',
          phone: '+92 333 4567890',
          partySize: 6,
          time: at(21, 0),
          tableName: 'F4',
          status: ReservationStatus.confirmed,
          note: 'Birthday — cake at 21:30'),
      Reservation(
          id: 'r4',
          guestName: 'Walk-in (Omar)',
          phone: '+92 345 1112223',
          partySize: 3,
          time: at(18, 15),
          tableName: 'O2',
          status: ReservationStatus.seated),
    ];
  }

  void add({
    required String guestName,
    required String phone,
    required int partySize,
    required DateTime time,
    String? tableName,
    String? note,
  }) {
    final reservation = Reservation(
      id: const Uuid().v4(),
      guestName: guestName,
      phone: phone,
      partySize: partySize,
      time: time,
      tableName: tableName,
      note: note,
      status: ReservationStatus.confirmed,
    );
    state = [...state, reservation]
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  void setStatus(String id, ReservationStatus status) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: status) else r,
    ];
  }

  void remove(String id) =>
      state = state.where((r) => r.id != id).toList();
}

final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<Reservation>>(
        (ref) => ReservationsNotifier());

/// Reservations sorted by time, earliest first.
final sortedReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = [...ref.watch(reservationsProvider)];
  list.sort((a, b) => a.time.compareTo(b.time));
  return list;
});
