import 'package:flutter/material.dart';

import '../services/settings_storage.dart';

/// Shared state for user preferences: theme mode and monthly budget.
///
/// Read by the app root (theme), the dashboard (budget progress) and the
/// settings screen.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  final SettingsStorage _storage;

  ThemeMode _themeMode = ThemeMode.system;
  double? _monthlyBudget;

  ThemeMode get themeMode => _themeMode;
  double? get monthlyBudget => _monthlyBudget;
  bool get hasBudget => _monthlyBudget != null;

  /// Loads saved settings. Falls back to defaults if storage fails, because
  /// a missing preference should never stop the app from starting.
  Future<void> load() async {
    try {
      _themeMode = await _storage.readThemeMode();
      _monthlyBudget = await _storage.readMonthlyBudget();
    } catch (_) {
      _themeMode = ThemeMode.system;
      _monthlyBudget = null;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _storage.writeThemeMode(mode);
    } catch (_) {
      // The theme still changes for this session even if it cannot be saved.
    }
  }

  /// Sets the monthly budget, or clears it when [budget] is null.
  /// Returns false if the change could not be saved.
  Future<bool> setMonthlyBudget(double? budget) async {
    final previous = _monthlyBudget;
    _monthlyBudget = budget;
    notifyListeners();
    try {
      await _storage.writeMonthlyBudget(budget);
      return true;
    } catch (_) {
      _monthlyBudget = previous;
      notifyListeners();
      return false;
    }
  }
}
