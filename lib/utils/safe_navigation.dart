import 'package:flutter/material.dart';

/// Navigation helper that ignores repeated fast taps.
///
/// Without this, tapping a button twice quickly opens the same screen twice.
/// After the first push, the screen we tapped on is no longer the top route
/// (`isCurrent` becomes false), so the second tap is simply ignored.
extension SafeNavigation on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) async {
    final route = ModalRoute.of(this);
    if (route != null && !route.isCurrent) return null;
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
