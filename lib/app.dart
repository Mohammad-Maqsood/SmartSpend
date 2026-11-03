import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

/// The root widget: sets the app name, the light/dark themes and home screen.
class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
