import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared spacing rules so screens look right on phones in both orientations.
class Layout {
  Layout._();

  /// Content never grows wider than this, so lines stay readable when the
  /// phone is turned sideways.
  static const maxContentWidth = 720.0;

  /// Page padding that centres content on wide screens and keeps it clear of
  /// camera cutouts in landscape.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 8,
    double bottom = 24,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final safe = MediaQuery.paddingOf(context);
    final side = math.max(16.0, (width - maxContentWidth) / 2);
    return EdgeInsets.fromLTRB(
      side + safe.left,
      top,
      side + safe.right,
      bottom,
    );
  }
}
