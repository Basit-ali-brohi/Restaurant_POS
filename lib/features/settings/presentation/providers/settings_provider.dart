import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsModel {
  final String restaurantName;
  final String address;
  final double taxRate;
  final bool isPrinterConnected;
  final String currency;

  const SettingsModel({
    this.restaurantName = "Neo Dining",
    this.address = "123 Innovation Blvd, Tech City",
    this.taxRate = 10.0,
    this.isPrinterConnected = false,
    this.currency = "USD",
  });

  SettingsModel copyWith({
    String? restaurantName,
    String? address,
    double? taxRate,
    bool? isPrinterConnected,
    String? currency,
  }) {
    return SettingsModel(
      restaurantName: restaurantName ?? this.restaurantName,
      address: address ?? this.address,
      taxRate: taxRate ?? this.taxRate,
      isPrinterConnected: isPrinterConnected ?? this.isPrinterConnected,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'address': address,
      'taxRate': taxRate,
      'isPrinterConnected': isPrinterConnected,
      'currency': currency,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      restaurantName: map['restaurantName'] ?? "Neo Dining",
      address: map['address'] ?? "123 Innovation Blvd, Tech City",
      taxRate: (map['taxRate'] ?? 10.0).toDouble(),
      isPrinterConnected: map['isPrinterConnected'] ?? false,
      currency: map['currency'] ?? "USD",
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(const SettingsModel()) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox('settings');
    final map = box.get('config');
    if (map != null) {
      state = SettingsModel.fromMap(Map<String, dynamic>.from(map));
    }
  }

  Future<void> _save() async {
    final box = Hive.isBoxOpen('settings') ? Hive.box('settings') : await Hive.openBox('settings');
    await box.put('config', state.toMap());
  }

  void updateRestaurantName(String name) {
    state = state.copyWith(restaurantName: name);
    _save();
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
    _save();
  }

  void updateTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
    _save();
  }

  void togglePrinter(bool isConnected) {
    state = state.copyWith(isPrinterConnected: isConnected);
    _save();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});
