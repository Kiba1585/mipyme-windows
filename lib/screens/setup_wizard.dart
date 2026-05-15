import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dashboard_screen.dart';
import 'import_screen.dart';
import 'onat_advanced_screen.dart';
import 'suppliers_screen.dart';
import 'payroll_screen.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _storage = const FlutterSecureStorage();

  static const _wizardCompletedKey = 'setup_wizard_completed';

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await _storage.write(key: _wizardCompletedKey, value: 'true');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildWelcomePage(),
                _buildImportPage(),
                _buildOnatRemindersPage(),
                _buildSuppliersEmployeesPage(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // --- Páginas del asistente ---

  Widget _buildWelcomePage() {
    return _buildStepPage(
      icon: Icons.store,
      title: '¡Bienvenido a MIPYME Windows!',
      description:
          'Este asistente le ayudará a configurar los aspectos básicos de su negocio en la PC. '
          'Puede saltar cualquier paso y completarlo más tarde desde el menú principal.',
      actionLabel: 'Comenzar',
      onAction: _nextPage,
    );
  }

  Widget _buildImportPage() {
    return _buildStepPage(
      icon: Icons.file_download,
      title: 'Importar datos del móvil',
      description:
          'Transfiera el archivo .mipyme que exportó desde la app MIPYME Suite en su teléfono. '
          'Así tendrá todos sus productos, clientes y ventas en la PC.',
      actionLabel: 'Importar ahora',
      onAction: () async {
        // Navega a la pantalla de importación (reutiliza ImportScreen)
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportScreen()),
        );
        _nextPage();
      },
      secondaryLabel: 'Saltar',
      onSecondary: _nextPage,
    );
  }

  Widget _buildOnatRemindersPage() {
    return _buildStepPage(
      icon: Icons.notifications_active,
      title: 'Recordatorios de impuestos',
      description:
          'Configure las fechas límite para el pago de impuestos. '
          'La aplicación le avisará cuando se acerque un vencimiento.',
      actionLabel: 'Configurar ONAT',
      onAction: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OnatAdvancedScreen()),
        );
        _nextPage();
      },
      secondaryLabel: 'Saltar',
      onSecondary: _nextPage,
    );
  }

  Widget _buildSuppliersEmployeesPage() {
    return _buildStepPage(
      icon: Icons.people,
      title: 'Proveedores y empleados',
      description:
          'Registre sus proveedores habituales y los trabajadores para gestionar '
          'compras, nóminas y obligaciones patronales.',
      actionLabel: 'Agregar proveedores / empleados',
      onAction: () async {
        // Abre proveedores, y al volver abre empleados
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuppliersScreen()),
        );
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PayrollScreen()),
        );
        _nextPage();
      },
      secondaryLabel: 'Saltar',
      onSecondary: _nextPage,
    );
  }

  // --- Widget reutilizable para cada paso ---

  Widget _buildStepPage({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // --- Barra inferior con indicador de progreso y botones ---

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Indicador de pasos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Botones de acción
          if (_currentPage < 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _finish(); // Saltar todo el asistente
                    } else {
                      _nextPage();
                    }
                  },
                  child: Text(_currentPage == 0 ? 'Saltar todo' : 'Siguiente'),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text('Continuar'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _finish,
                child: const Text('FINALIZAR CONFIGURACIÓN'),
              ),
            ),
        ],
      ),
    );
  }
}