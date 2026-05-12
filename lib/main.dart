import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MipymeWindowsApp());
}

class MipymeWindowsApp extends StatelessWidget {
  const MipymeWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIPYME Windows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ActivationScreen(),
    );
  }
}