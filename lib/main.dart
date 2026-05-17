import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/activation_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_scope.dart';
import 'services/alert_service.dart';
import 'services/scheduled_backup_service.dart';

/// Guarda el error en un archivo y muestra un MessageBox indicando dónde
void guardarYMostrarError(String title, String message) {
  try {
    // Obtener la carpeta donde está el ejecutable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final logFile = File('$exeDir/error_log.txt');
    logFile.writeAsStringSync(message);
  } catch (_) {
    // Si falla la escritura, al menos mostramos el error
  }

  // Mostrar el MessageBox con el mismo error y la ubicación
  final user32 = DynamicLibrary.open('user32.dll');
  final MessageBoxW = user32.lookupFunction<
      Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, Int32 uType),
      int Function(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, int uType)>('MessageBoxW');

  final msg = 'Error fatal (también guardado en error_log.txt):\n\n$message';
  final text = msg.toNativeUtf16();
  final caption = title.toNativeUtf16();
  MessageBoxW(0, text, caption, 0x00000030); // MB_ICONERROR | MB_OK
  malloc.free(text);
  malloc.free(caption);
}

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
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
        home: const ActivationScreen(),
      ),
    );
  }
}