import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';
import '../models/budget.dart';
import '../models/asset.dart';
import '../models/employee.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      final db = await _initDatabase().timeout(const Duration(seconds: 10));
      _database = db;
      return db;
    } catch (e) {
      throw Exception('No se pudo abrir la base de datos. Error: $e');
    }
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'mipyme_windows.db');
    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7, // <-- Se incrementa a 7 para añadir la tabla products
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                phone TEXT,
                products TEXT,
                notes TEXT
              )
            ''');
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS budgets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                month TEXT NOT NULL UNIQUE,
                projected_income REAL NOT NULL,
                projected_expenses REAL NOT NULL,
                notes TEXT
              )
            ''');
          }
          if (oldVersion < 4) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS employees (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                base_salary REAL NOT NULL,
                notes TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS assets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                value REAL NOT NULL,
                useful_life_years INTEGER NOT NULL,
                acquisition_date TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 5) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS cashflow_projections (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                month TEXT NOT NULL UNIQUE,
                projected_income REAL NOT NULL,
                projected_expenses REAL NOT NULL
              )
            ''');
          }
          if (oldVersion < 6) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS reminders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                deadline TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 7) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY,
                product_code TEXT NOT NULL,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                price REAL NOT NULL,
                cost REAL,
                stock REAL NOT NULL,
                unit TEXT NOT NULL
              )
            ''');
          }
        },
      ),
    );
  }

  static Future<void> _createTables(Database db) async {
    // Todas las tablas anteriores, incluyendo products
    await db.execute('''
      CREATE TABLE imported_data (
        id INTEGER PRIMARY KEY,
        file_name TEXT NOT NULL,
        import_date TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tax_calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period TEXT NOT NULL,
        gross_income REAL NOT NULL,
        expenses REAL NOT NULL,
        taxable_income REAL NOT NULL,
        tax_amount REAL NOT NULL,
        calculated_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        products TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        projected_income REAL NOT NULL,
        projected_expenses REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        base_salary REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value REAL NOT NULL,
        useful_life_years INTEGER NOT NULL,
        acquisition_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cashflow_projections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        projected_income REAL NOT NULL,
        projected_expenses REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        deadline TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // NUEVA TABLA products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        product_code TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        cost REAL,
        stock REAL NOT NULL,
        unit TEXT NOT NULL
      )
    ''');
  }

  // ... (métodos existentes de imported_data, financial_records, etc.)

  // ==================== PRODUCTS ====================
  static Future<void> insertProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name');
  }

  // ==================== RESTO DE MÉTODOS (IMPORTED_DATA, FINANCIAL_RECORDS, etc.) ====================
  // Se mantienen todos los métodos que ya tenías (saveImportedData, getImportedFiles,
  // addFinancialRecord, getFinancialRecords, getTotalByType, etc.)
  // Asegúrate de copiar TODOS los demás métodos desde la versión anterior.
}