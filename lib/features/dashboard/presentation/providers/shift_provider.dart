import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ShiftEventType { opened, cashIn, cashOut, closed }

class ShiftEvent {
  final DateTime time;
  final ShiftEventType type;
  final double amount;
  final String note;
  const ShiftEvent({required this.time, required this.type, required this.amount, this.note = ''});
}

class ShiftState {
  final bool isOpen;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double closingCash;
  final List<ShiftEvent> events;

  const ShiftState({
    required this.isOpen,
    required this.openedAt,
    required this.closedAt,
    required this.openingCash,
    required this.closingCash,
    required this.events,
  });

  factory ShiftState.initial() {
    return const ShiftState(
      isOpen: false,
      openedAt: null,
      closedAt: null,
      openingCash: 0,
      closingCash: 0,
      events: [],
    );
  }

  ShiftState copyWith({
    bool? isOpen,
    DateTime? openedAt,
    DateTime? closedAt,
    double? openingCash,
    double? closingCash,
    List<ShiftEvent>? events,
  }) {
    return ShiftState(
      isOpen: isOpen ?? this.isOpen,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      events: events ?? this.events,
    );
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier();
});

final shiftCashInTotalProvider = Provider<double>((ref) {
  final s = ref.watch(shiftProvider);
  return s.events.where((e) => e.type == ShiftEventType.cashIn).fold<double>(0, (sum, e) => sum + e.amount);
});

final shiftCashOutTotalProvider = Provider<double>((ref) {
  final s = ref.watch(shiftProvider);
  return s.events.where((e) => e.type == ShiftEventType.cashOut).fold<double>(0, (sum, e) => sum + e.amount);
});

final shiftExpectedCashProvider = Provider<double>((ref) {
  final s = ref.watch(shiftProvider);
  final cashIn = ref.watch(shiftCashInTotalProvider);
  final cashOut = ref.watch(shiftCashOutTotalProvider);
  return s.openingCash + cashIn - cashOut;
});

class ShiftNotifier extends StateNotifier<ShiftState> {
  ShiftNotifier() : super(ShiftState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox('shift');
    final m = box.get('state');
    if (m != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(m);
      final List ev = (data['events'] as List? ?? []);
      final events = ev.map((e) {
        final mm = Map<String, dynamic>.from(e);
        return ShiftEvent(
          time: DateTime.parse(mm['time'] as String),
          type: ShiftEventType.values.firstWhere((t) => t.name == mm['type']),
          amount: (mm['amount'] as num).toDouble(),
          note: (mm['note'] as String?) ?? '',
        );
      }).toList();
      state = ShiftState(
        isOpen: data['isOpen'] as bool? ?? false,
        openedAt: (data['openedAt'] as String?) != null ? DateTime.parse(data['openedAt'] as String) : null,
        closedAt: (data['closedAt'] as String?) != null ? DateTime.parse(data['closedAt'] as String) : null,
        openingCash: (data['openingCash'] as num?)?.toDouble() ?? 0,
        closingCash: (data['closingCash'] as num?)?.toDouble() ?? 0,
        events: events,
      );
    }
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen('shift') ? Hive.box('shift') : await Hive.openBox('shift');
    await box.put('state', {
      'isOpen': state.isOpen,
      'openedAt': state.openedAt?.toIso8601String(),
      'closedAt': state.closedAt?.toIso8601String(),
      'openingCash': state.openingCash,
      'closingCash': state.closingCash,
      'events': state.events
          .map((e) => {
                'time': e.time.toIso8601String(),
                'type': e.type.name,
                'amount': e.amount,
                'note': e.note,
              })
          .toList(),
    });
  }

  void openShift({required double openingCash, String note = ''}) {
    final now = DateTime.now();
    state = ShiftState(
      isOpen: true,
      openedAt: now,
      closedAt: null,
      openingCash: openingCash,
      closingCash: 0,
      events: [ShiftEvent(time: now, type: ShiftEventType.opened, amount: openingCash, note: note)],
    );
    _save();
  }

  void cashIn({required double amount, String note = ''}) {
    if (!state.isOpen) return;
    final now = DateTime.now();
    state = state.copyWith(events: [ShiftEvent(time: now, type: ShiftEventType.cashIn, amount: amount, note: note), ...state.events]);
    _save();
  }

  void cashOut({required double amount, String note = ''}) {
    if (!state.isOpen) return;
    final now = DateTime.now();
    state = state.copyWith(events: [ShiftEvent(time: now, type: ShiftEventType.cashOut, amount: amount, note: note), ...state.events]);
    _save();
  }

  void closeShift({required double closingCash, String note = ''}) {
    if (!state.isOpen) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOpen: false,
      closedAt: now,
      closingCash: closingCash,
      events: [ShiftEvent(time: now, type: ShiftEventType.closed, amount: closingCash, note: note), ...state.events],
    );
    _save();
  }

  void reset() {
    state = ShiftState.initial();
    _save();
  }
}
