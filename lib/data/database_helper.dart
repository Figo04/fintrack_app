import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper menggunakan Singleton pattern untuk mengelola koneksi database SQLite
/// Berfungsi sebagai layer akses data untuk aplikasi FinTrack
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Factory constructor untuk mengembalikan instance yang sama
  factory DatabaseHelper() => _instance;
  
  // Private constructor untuk mencegah instantiation langsung
  DatabaseHelper._internal();

  /// Getter untuk mendapatkan instance database
  /// Menggunakan lazy initialization - database dibuat hanya saat dibutuhkan
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database dengan konfigurasi dan path
  Future<Database> _initDatabase() async {
    // Mendapatkan path untuk database di direktori aplikasi
    String path = join(await getDatabasesPath(), 'fintrack.db');

    return await openDatabase(
      path,
      version: 3, // Version 3 untuk mendukung Firebase integration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat semua tabel yang diperlukan saat database pertama kali dibuat
  Future<void> _createTables(Database db, int version) async {
    final now = DateTime.now().toIso8601String();

    // Tabel untuk menyimpan data user dari Firebase Authentication
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        username TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel untuk menyimpan jenis-jenis akun keuangan (Bank, E-wallet, dll)
    await db.execute('''
      CREATE TABLE account_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel untuk menyimpan akun keuangan milik user
    await db.execute('''
      CREATE TABLE user_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_type_id INTEGER NOT NULL,
        account_name TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (account_type_id) REFERENCES account_types (id)
      )
    ''');

    // Tabel untuk menyimpan transaksi keuangan
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        type TEXT NOT NULL, -- 'income' atau 'expense'
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (account_id) REFERENCES user_accounts (id)
      )
    ''');

    // Insert data default untuk account types
    await _insertDefaultAccountTypes(db, now);
  }

  /// Menambahkan data default untuk jenis-jenis akun
  Future<void> _insertDefaultAccountTypes(Database db, String now) async {
    final defaultAccountTypes = [
      {'name': 'Uang Tunai', 'icon': 'money'},
      {'name': 'BCA', 'icon': 'account_balance'},
      {'name': 'BRI', 'icon': 'account_balance'},
      {'name': 'Dana', 'icon': 'account_balance_wallet'},
      {'name': 'Gopay', 'icon': 'account_balance_wallet_outlined'},
      {'name': 'Jago', 'icon': 'account_balance'},
      {'name': 'Jenius', 'icon': 'account_balance'},
      {'name': 'Mandiri', 'icon': 'account_balance'},
      {'name': 'OVO', 'icon': 'account_balance_wallet'},
    ];

    for (final accountType in defaultAccountTypes) {
      await db.insert('account_types', {
        'name': accountType['name'],
        'icon': accountType['icon'],
        'created_at': now,
      });
    }
  }

  /// Menangani upgrade database saat version berubah
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _upgradeToVersion3(db);
    }
  }

  /// Upgrade spesifik untuk version 3 (Firebase integration)
  Future<void> _upgradeToVersion3(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Buat tabel users untuk Firebase integration
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        username TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tambahkan kolom account_name jika belum ada
    try {
      await db.execute('ALTER TABLE user_accounts ADD COLUMN account_name TEXT');
    } catch (e) {
      print('Column account_name might already exist: $e');
    }

    // Update account types dengan data terbaru
    await db.delete('account_types');
    await _insertDefaultAccountTypes(db, now);
  }

  // ============================
  // USER MANAGEMENT METHODS
  // ============================

  /// Menambahkan atau mengupdate user dari Firebase Authentication
  /// Mengembalikan user ID dari database lokal
  Future<int> insertOrUpdateUser({
    required String firebaseUid,
    required String email,
    String? username,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Cek apakah user sudah terdaftar di database lokal
    final existingUser = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );

    if (existingUser.isNotEmpty) {
      // Update data user yang sudah ada
      await db.update(
        'users',
        {
          'email': email,
          'username': username,
          'updated_at': now,
        },
        where: 'firebase_uid = ?',
        whereArgs: [firebaseUid],
      );
      return existingUser.first['id'] as int;
    } else {
      // Buat user baru
      return await db.insert('users', {
        'firebase_uid': firebaseUid,
        'email': email,
        'username': username,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Mendapatkan data user berdasarkan Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // ============================
  // TRANSACTION MANAGEMENT METHODS
  // ============================

  /// Mendapatkan data transaksi berdasarkan ID
  Future<Map<String, dynamic>?> getTransactionById(int transactionId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Menghapus transaksi berdasarkan ID
  Future<void> deleteTransactionById(int transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Mendapatkan data transaksi beserta detail akun
  /// Berguna untuk verifikasi keamanan dan tampilan detail
  Future<Map<String, dynamic>?> getTransactionWithAccountDetails(
      int transactionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.*, 
             ua.user_id as account_owner_id, 
             ua.balance as account_balance, 
             at.name as account_name, 
             at.icon as account_icon
      FROM transactions t
      INNER JOIN user_accounts ua ON t.account_id = ua.id
      INNER JOIN account_types at ON ua.account_type_id = at.id
      WHERE t.id = ?
    ''', [transactionId]);

    return result.isNotEmpty ? result.first : null;
  }

  // ============================
  // ACCOUNT MANAGEMENT METHODS
  // ============================

  /// Mengupdate saldo akun
  Future<void> updateAccountBalance(int accountId, double newBalance) async {
    final db = await database;
    await db.update(
      'user_accounts',
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Mendapatkan saldo akun
  Future<double> getAccountBalance(int accountId) async {
    final db = await database;
    final result = await db.query(
      'user_accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
    );

    if (result.isNotEmpty) {
      return (result.first['balance'] as double?) ?? 0.0;
    }
    return 0.0;
  }

  // ============================
  // SECURITY & VALIDATION METHODS
  // ============================

  /// Verifikasi kepemilikan transaksi untuk keamanan
  /// Memastikan user hanya bisa mengakses transaksi miliknya sendiri
  Future<bool> verifyTransactionOwnership(int transactionId, int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM transactions t
      INNER JOIN user_accounts ua ON t.account_id = ua.id
      WHERE t.id = ? AND ua.user_id = ?
    ''', [transactionId, userId]);

    return (result.first['count'] as int) > 0;
  }

  // ============================
  // ANALYTICS & REPORTING METHODS
  // ============================

  /// Mendapatkan statistik transaksi user untuk dashboard
  Future<Map<String, dynamic>> getTransactionStats(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) as total_income,
        SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) as total_expense,
        SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END) as net_balance
      FROM transactions t
      INNER JOIN user_accounts ua ON t.account_id = ua.id
      WHERE ua.user_id = ?
    ''', [userId]);

    return result.first;
  }

  // ============================
  // DEVELOPMENT & MAINTENANCE METHODS
  // ============================

  /// Reset database - hanya untuk development
  /// PERINGATAN: Akan menghapus semua data!
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'fintrack.db');
    await deleteDatabase(path);
    _database = null;
  }

  /// Menutup koneksi database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

