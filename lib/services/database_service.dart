import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';
import '../models/budget.dart';

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
        version: 3, // Incrementada por nuevas tablas
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
        },
      ),
    );
    return _database!;
  }

  static Future<void> _createTables(Database db) async {
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
  }

  // ==================== IMPORTED DATA ====================
  static Future<void> saveImportedData(String fileName, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('imported_data', {
      'file_name': fileName,
      'import_date': DateTime.now().toIso8601String(),
      'data': data.toString(),
    });
  }

  static Future<List<Map<String, dynamic>>> getImportedFiles() async {
    final db = await database;
    return await db.query('imported_data', orderBy: 'import_date DESC');
  }

  // ==================== FINANCIAL RECORDS ====================
  static Future<int> addFinancialRecord({
    required String date,
    required String type,
    required double amount,
    required String category,
    String? description,
  }) async {
    final db = await database;
    return await db.insert('financial_records', {
      'date': date,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
    });
  }

  static Future<List<Map<String, dynamic>>> getFinancialRecords({
    String? startDate,
    String? endDate,
    String? type,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (startDate != null) { where += ' AND date >= ?'; args.add(startDate); }
    if (endDate != null) { where += ' AND date <= ?'; args.add(endDate); }
    if (type != null) { where += ' AND type = ?'; args.add(type); }
    return await db.query('financial_records', where: where, whereArgs: args, orderBy: 'date DESC');
  }

  static Future<double> getTotalByType(String type, String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM financial_records WHERE type = ? AND date BETWEEN ? AND ?',
      [type, startDate, endDate],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== TAX CALCULATIONS ====================
  static Future<int> saveTaxCalculation({
    required String period,
    required double grossIncome,
    required double expenses,
    required double taxableIncome,
    required double taxAmount,
  }) async {
    final db = await database;
    return await db.insert('tax_calculations', {
      'period': period,
      'gross_income': grossIncome,
      'expenses': expenses,
      'taxable_income': taxableIncome,
      'tax_amount': taxAmount,
      'calculated_date': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTaxHistory() async {
    final db = await database;
    return await db.query('tax_calculations', orderBy: 'period DESC');
  }

  // ==================== SUPPLIERS ====================
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

  // ==================== BUDGETS ====================
  static Future<int> saveBudget(Budget budget) async {
    final db = await database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Budget?> getBudget(String month) async {
    final db = await database;
    final maps = await db.query('budgets', where: 'month = ?', whereArgs: [month]);
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }
}
