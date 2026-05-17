import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/activation_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'services/alert_service.dart';
import 'services/scheduled_backup_service.dart';

// ========================================================
// Función para mostrar un cuadro de error nativo de Windows
// usando la API MessageBoxW de user32.dll
// ========================================================
void showNativeError(String title, String message) {
  final user32 = DynamicLibrary.open('user32.dll');
  final MessageBoxW = user32.lookupFunction<
      Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, Int32 uType),
      int Function(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, int uType)>('MessageBoxW');

  final text = message.toNativeUtf16();
  final caption = title.toNativeUtf16();
  MessageBoxW(0, text, caption, 0x00000030); // MB_ICONERROR | MB_OK
  free(text);
  free(caption);
}

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicializar FFI de SQLite (obligatorio en Windows)
    sqfliteFfiInit();

    // Servicios que deben correr antes de la UI
    AlertService.initialize();
    AlertService.startPeriodicCheck();

    // Captura errores de Flutter en runtime (por si acaso)
    FlutterError.onError = (details) {
      // Podrías usar un diálogo de Flutter, pero si la app ya está corriendo
      // mostramos en consola y en un MessageBox solo para errores fatales
      debugPrint(details.exceptionAsString());
    };

    runApp(const MipymeWindowsApp());
  } catch (e, stack) {
    // Error fatal antes de que Flutter pueda abrirse
    final errorMessage = 'Error: $e\n\nStack:\n$stack';
    showNativeError('Error fatal', errorMessage);
    exit(1); // Termina la app para que no quede colgada
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
        home: const ActivationScreen(),
      ),
    );
  }
}