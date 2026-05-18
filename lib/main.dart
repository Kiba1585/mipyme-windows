import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';            // añadido para hash
import 'dart:convert';                          // añadido para utf8
import 'screens/activation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'services/alert_service.dart';
import 'services/scheduled_backup_service.dart';
import 'services/license_service.dart';

void guardarYMostrarError(String title, String message) {
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final logFile = File('$exeDir/error_log.txt');
    logFile.writeAsStringSync(message);
  } catch (_) {}

  final user32 = DynamicLibrary.open('user32.dll');
  final MessageBoxW = user32.lookupFunction<
      Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, Int32 uType),
      int Function(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, int uType)>('MessageBoxW');

  final msg = 'Error fatal (guardado en error_log.txt):\n\n$message';
  final text = msg.toNativeUtf16();
  final caption = title.toNativeUtf16();
  MessageBoxW(0, text, caption, 0x00000030);
  malloc.free(text);
  malloc.free(caption);
}

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    AlertService.initialize();
    AlertService.startPeriodicCheck();

    FlutterError.onError = (details) {
      debugPrint(details.exceptionAsString());
    };

    runApp(const MipymeWindowsApp());
  } catch (e, stack) {
    final errorMsg = 'Error: $e\n\nStack:\n$stack';
    guardarYMostrarError('Error fatal', errorMsg);
    exit(1);
  }
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

  void _changeTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    _storage.write(key: 'dark_mode', value: isDark.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      onThemeChanged: _changeTheme,
      themeMode: _themeMode,
      child: MaterialApp(
        title: 'MIPYME Windows',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: const StartupScreen(),
      ),
    );
  }
}

/// Pantalla que decide a dónde ir según si ya hay dueños guardados y el hash coincide
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    // 1) Obtener dueños desde almacenamiento seguro
    final owners = await LicenseService.getAllOwners();
    if (owners.isNotEmpty) {
      // Tenemos dueños guardados, verificar hash de archivo
      final owner = await LicenseService.getActiveOwner() ?? owners.first;
      final expectedHash = sha256
          .convert(utf8.encode('${owner.ownerName}|${owner.phoneNumber}|${owner.expiryDate.toIso8601String()}'))
          .toString();

      try {
        final dir = await getApplicationDocumentsDirectory();
        final checkFile = File(p.join(dir.path, 'license_check.txt'));
        if (await checkFile.exists()) {
          final savedHash = await checkFile.readAsString();
          if (savedHash.trim() == expectedHash) {
            // Hash válido → ir al dashboard
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
            return;
          }
        }
      } catch (_) {}
      // Si el archivo no existe o el hash no coincide, borrar dueños y forzar reactivación
      await LicenseService.deactivate();
    }

    // Si no hay dueños o el hash era inválido, mostrar activación
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ActivationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}