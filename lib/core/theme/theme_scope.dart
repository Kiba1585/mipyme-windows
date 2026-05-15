import 'package:flutter/material.dart';

class ThemeScope extends InheritedWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode themeMode;

  const ThemeScope({
    super.key,
    required this.onThemeChanged,
    required this.themeMode,
    required super.child,
  });

  static ThemeScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>();
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) {
    return onThemeChanged != oldWidget.onThemeChanged || themeMode != oldWidget.themeMode;
  }
}