import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/activation_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/alert_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AlertService.initialize();
  AlertService.startPeriodicCheck();
  runApp(const MipymeWindowsApp());
}

class MipymeWindowsApp extends StatefulWidget {
  const MipymeWindowsApp({super.key});

  @override
  State<MipymeWindowsApp> createState() => _MipymeWindowsAppState();
}

class _MipymeWindowsAppState extends State<MipymeWindowsApp> {
  final _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final darkMode = await _storage.read(key: 'dark_mode');
    if (darkMode == 'true') {
      setState(() => _themeMode = ThemeMode.dark);
    }
  }

  void changeTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    _storage.write(key: 'dark_mode', value: isDark.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIPYME Windows',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: ActivationScreen(onThemeChanged: changeTheme),
    );
  }
}