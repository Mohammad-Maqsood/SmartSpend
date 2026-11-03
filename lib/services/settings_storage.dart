import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves and loads user preferences (theme and monthly budget) on the device.
class SettingsStorage {
  static const _themeModeKey = 'spendwise.themeMode';
  static const _budgetKey = 'spendwise.monthlyBudget';

  Future<ThemeMode> readThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  /// Returns the saved monthly budget, or null when no budget is set.
  Future<double?> readMonthlyBudget() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble(_budgetKey);
  }

  /// Saves [budget], or removes it when [budget] is null.
  Future<void> writeMonthlyBudget(double? budget) async {
    final preferences = await SharedPreferences.getInstance();
    if (budget == null) {
      await preferences.remove(_budgetKey);
    } else {
      await preferences.setDouble(_budgetKey, budget);
    }
  }
}
