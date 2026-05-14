import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/alert_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AlertService.initialize();
  AlertService.startPeriodicCheck();
  runApp(const MipymeWindowsApp());
}

class MipymeWindowsApp extends StatelessWidget {
  const MipymeWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIPYME Windows',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const ActivationScreen(),
    );
  }
}