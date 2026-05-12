import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'mipyme_windows.db');
    _database = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2, // <-- incrementamos la versión
        onCreate: (db, version) async {
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
        },
      ),
    );
    return _database!;
  }

  // Métodos existentes (saveImportedData, getImportedFiles, etc.) se mantienen...
  // ... copia todos los métodos que ya tenías exactamente igual.

  // NUEVOS MÉTODOS PARA PROVEEDORES

  static Future<int> addSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier.toMap());
  }

  static Future<List<Supplier>> getSuppliers({String? search}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (search != null && search.isNotEmpty) {
      maps = await db.query('suppliers',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%$search%', '%$search%'],
          orderBy: 'name');
    } else {
      maps = await db.query('suppliers', orderBy: 'name');
    }
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  static Future<void> updateSupplier(Supplier supplier) async {
    final db = await database;
    await db.update('suppliers', supplier.toMap(),
        where: 'id = ?', whereArgs: [supplier.id]);
  }

  static Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}

// ... (resto de métodos existentes sin cambios)
