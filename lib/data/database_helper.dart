import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fintrack.db');

    return await openDatabase(
      path,
      version: 3, // Increased version for Firebase integration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabel users untuk menyimpan data Firebase users
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

    // Tabel account_types
    await db.execute('''
      CREATE TABLE account_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel user_accounts dengan foreign key ke users table
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

    // Tabel transactions dengan foreign key ke users table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (account_id) REFERENCES user_accounts (id)
      )
    ''');

    // Insert default account types
    final now = DateTime.now().toIso8601String();

    await db.insert('account_types', {
      'name': 'Uang Tunai',
      'icon': 'money',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'BCA',
      'icon': 'account_balance',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'BRI',
      'icon': 'account_balance',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'Dana',
      'icon': 'account_balance_wallet',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'Gopay',
      'icon': 'account_balance_wallet_outlined',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'Jago',
      'icon': 'account_balance',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'Jenius',
      'icon': 'account_balance',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'Mandiri',
      'icon': 'account_balance',
      'created_at': now,
    });
    await db.insert('account_types', {
      'name': 'OVO',
      'icon': 'account_balance_wallet',
      'created_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Create users table for Firebase integration
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

      // Add account_name column if it doesn't exist
      try {
        await db.execute('ALTER TABLE user_accounts ADD COLUMN account_name TEXT');
      } catch (e) {
        print('Column account_name might already exist: $e');
      }

      // Update account types
      await db.delete('account_types');
      final now = DateTime.now().toIso8601String();

      await db.insert('account_types', {
        'name': 'Uang Tunai',
        'icon': 'money',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'BCA',
        'icon': 'account_balance',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'BRI',
        'icon': 'account_balance',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'Dana',
        'icon': 'account_balance_wallet',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'Gopay',
        'icon': 'account_balance_wallet_outlined',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'Jago',
        'icon': 'account_balance',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'Jenius',
        'icon': 'account_balance',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'Mandiri',
        'icon': 'account_balance',
        'created_at': now,
      });
      await db.insert('account_types', {
        'name': 'OVO',
        'icon': 'account_balance_wallet',
        'created_at': now,
      });
    }
  }

  // Method untuk menambah/update user dari Firebase
  Future<int> insertOrUpdateUser({
    required String firebaseUid,
    required String email,
    String? username,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Cek apakah user sudah ada
    final existingUser = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );

    if (existingUser.isNotEmpty) {
      // Update existing user
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
      // Insert new user
      return await db.insert('users', {
        'firebase_uid': firebaseUid,
        'email': email,
        'username': username,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // Method untuk mendapatkan user berdasarkan Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // Method untuk reset database (development only)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'fintrack.db');
    await deleteDatabase(path);
    _database = null;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}