import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/database/db_service.dart';

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
    this.currency = "PKR",
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
      currency: map['currency'] ?? "PKR",
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(const SettingsModel()) {
    _load();
  }

  final _db = DbService.instance;

  Future<void> _load() async {
    if (!_db.isConnected) return;
    final raw = await _db.loadState('settings');
    if (raw != null && raw.isNotEmpty) {
      state = SettingsModel.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    }
  }

  Future<void> _save() async {
    await _db.saveState('settings', jsonEncode(state.toMap()));
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
