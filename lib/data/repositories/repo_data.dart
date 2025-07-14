import 'package:fintrack_apps/data/database_helper.dart';
import 'package:fintrack_apps/data/models/model_data.dart';

/// Repository pattern untuk mengelola operasi keuangan
/// Berfungsi sebagai layer abstraksi antara UI dan DatabaseHelper
/// Menangani business logic dan data transformation
class FinancialRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================
  // ACCOUNT TYPES MANAGEMENT
  // ============================

  /// Mendapatkan semua jenis akun yang tersedia
  /// Contoh: Bank BCA, Dana, Gopay, dll
  Future<List<AccountType>> getAccountTypes() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('account_types');
      return List.generate(maps.length, (i) => AccountType.fromMap(maps[i]));
    } catch (e) {
      print('Error getting account types: $e');
      return [];
    }
  }

  // ============================
  // USER ACCOUNTS MANAGEMENT
  // ============================

  /// Menambahkan akun baru untuk user
  /// Mengembalikan ID akun yang baru dibuat
  Future<int> insertUserAccount(UserAccount account) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('user_accounts', account.toMap());
    } catch (e) {
      print('Error inserting user account: $e');
      rethrow;
    }
  }

  /// Mendapatkan semua akun milik user tertentu
  Future<List<UserAccount>> getUserAccounts(int userId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'user_accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return List.generate(maps.length, (i) => UserAccount.fromMap(maps[i]));
    } catch (e) {
      print('Error getting user accounts: $e');
      return [];
    }
  }

  /// Mendapatkan akun spesifik berdasarkan userId dan accountId
  /// Berguna untuk validasi kepemilikan akun
  Future<UserAccount?> getUserAccount(int userId, int accountId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'user_accounts',
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, accountId],
      );
      
      if (maps.isNotEmpty) {
        return UserAccount.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user account: $e');
      return null;
    }
  }

  /// Mengupdate data akun user
  Future<void> updateUserAccount(UserAccount account) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'user_accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
    } catch (e) {
      print('Error updating user account: $e');
      rethrow;
    }
  }

  /// Mendapatkan akun user beserta detail jenis akun
  /// Berguna untuk menampilkan nama dan icon akun
  Future<List<Map<String, dynamic>>> getUserAccountsWithDetails(
      int userId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT ua.*, at.name as account_name, at.icon as account_icon
        FROM user_accounts ua
        JOIN account_types at ON ua.account_type_id = at.id
        WHERE ua.user_id = ?
      ''', [userId]);

      return maps.map((map) {
        return {
          'account': UserAccount.fromMap(map),
          'accountType': AccountType(
            id: map['account_type_id'],
            name: map['account_name'],
            icon: map['account_icon'],
            createdAt: DateTime.parse(map['created_at']),
          ),
        };
      }).toList();
    } catch (e) {
      print('Error getting user accounts with details: $e');
      return [];
    }
  }

  // ============================
  // TRANSACTIONS MANAGEMENT
  // ============================

  /// Menambahkan transaksi baru
  /// Mengembalikan ID transaksi yang baru dibuat
  Future<int> insertTransaction(Transaction transaction) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('transactions', transaction.toMap());
    } catch (e) {
      print('Error inserting transaction: $e');
      rethrow;
    }
  }

  /// Mendapatkan daftar transaksi untuk user tertentu
  /// Diurutkan berdasarkan tanggal terbaru
  Future<List<Transaction>> getTransactions(int userId, {int limit = 50}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Mendapatkan transaksi spesifik berdasarkan ID
  Future<Transaction?> getTransactionById(int transactionId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (maps.isNotEmpty) {
        return Transaction.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  /// Menghapus transaksi berdasarkan ID
  Future<void> deleteTransaction(int transactionId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Mendapatkan transaksi dengan detail akun untuk tampilan yang lebih informatif
  /// Termasuk nama akun, icon, dan saldo
  Future<List<Map<String, dynamic>>> getTransactionsWithAccountDetails(
      int userId, {int limit = 50}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, 
               ua.balance as account_balance, 
               at.name as account_name, 
               at.icon as account_icon
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        INNER JOIN account_types at ON ua.account_type_id = at.id
        WHERE ua.user_id = ?
        ORDER BY t.created_at DESC
        LIMIT ?
      ''', [userId, limit]);

      return maps.map((map) {
        return {
          'transaction': Transaction.fromMap(map),
          'accountName': map['account_name'],
          'accountIcon': map['account_icon'],
          'accountBalance': map['account_balance'],
        };
      }).toList();
    } catch (e) {
      print('Error getting transactions with account details: $e');
      return [];
    }
  }

  /// Mendapatkan transaksi user dengan informasi tambahan
  /// Alternatif method yang lebih sederhana
  Future<List<Transaction>> getUserTransactions(int userId, {int limit = 50}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, ua.account_name, at.name as account_type_name
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        INNER JOIN account_types at ON ua.account_type_id = at.id
        WHERE ua.user_id = ?
        ORDER BY t.created_at DESC
        LIMIT ?
      ''', [userId, limit]);

      return List.generate(maps.length, (i) {
        return Transaction.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // ============================
  // FINANCIAL ANALYTICS
  // ============================

  /// Menghitung total pemasukan user
  /// Menjumlahkan semua transaksi bertipe 'income'
  Future<double> getTotalIncome(int userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(t.amount) as total
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        WHERE ua.user_id = ? AND t.type = 'income'
      ''', [userId]);

      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      print('Error getting total income: $e');
      return 0.0;
    }
  }

  /// Menghitung total pengeluaran user
  /// Menjumlahkan semua transaksi bertipe 'expense'
  Future<double> getTotalExpense(int userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(t.amount) as total
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        WHERE ua.user_id = ? AND t.type = 'expense'
      ''', [userId]);

      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      print('Error getting total expense: $e');
      return 0.0;
    }
  }

  /// Menghitung saldo bersih user (income - expense)
  /// Berguna untuk dashboard dan laporan keuangan
  Future<double> getNetBalance(int userId) async {
    try {
      final totalIncome = await getTotalIncome(userId);
      final totalExpense = await getTotalExpense(userId);
      return totalIncome - totalExpense;
    } catch (e) {
      print('Error calculating net balance: $e');
      return 0.0;
    }
  }

  /// Mendapatkan ringkasan keuangan user
  /// Mengembalikan statistik lengkap dalam satu method
  Future<Map<String, double>> getFinancialSummary(int userId) async {
    try {
      final totalIncome = await getTotalIncome(userId);
      final totalExpense = await getTotalExpense(userId);
      final netBalance = totalIncome - totalExpense;

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netBalance': netBalance,
      };
    } catch (e) {
      print('Error getting financial summary: $e');
      return {
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'netBalance': 0.0,
      };
    }
  }

  // ============================
  // SECURITY & VALIDATION
  // ============================

  /// Verifikasi kepemilikan transaksi untuk keamanan
  /// Memastikan user hanya bisa mengakses transaksi miliknya sendiri
  Future<bool> verifyTransactionOwnership(int transactionId, int userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        WHERE t.id = ? AND ua.user_id = ?
      ''', [transactionId, userId]);

      return (result.first['count'] as int) > 0;
    } catch (e) {
      print('Error verifying transaction ownership: $e');
      return false;
    }
  }

  /// Verifikasi kepemilikan akun
  /// Memastikan user hanya bisa mengakses akun miliknya sendiri
  Future<bool> verifyAccountOwnership(int accountId, int userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'user_accounts',
        where: 'id = ? AND user_id = ?',
        whereArgs: [accountId, userId],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error verifying account ownership: $e');
      return false;
    }
  }

  // ============================
  // HELPER METHODS
  // ============================

  /// Mendapatkan jumlah transaksi berdasarkan kategori
  /// Berguna untuk analisis pengeluaran per kategori
  Future<Map<String, double>> getExpenseByCategory(int userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT t.category, SUM(t.amount) as total
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        WHERE ua.user_id = ? AND t.type = 'expense'
        GROUP BY t.category
      ''', [userId]);

      Map<String, double> categoryExpenses = {};
      for (final row in result) {
        categoryExpenses[row['category'] as String] = 
            (row['total'] as double?) ?? 0.0;
      }

      return categoryExpenses;
    } catch (e) {
      print('Error getting expense by category: $e');
      return {};
    }
  }

  /// Mendapatkan transaksi dalam periode tertentu
  /// Berguna untuk laporan bulanan/tahunan
  Future<List<Transaction>> getTransactionsByDateRange(
    int userId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*
        FROM transactions t
        INNER JOIN user_accounts ua ON t.account_id = ua.id
        WHERE ua.user_id = ? 
          AND t.date >= ? 
          AND t.date <= ?
        ORDER BY t.created_at DESC
      ''', [
        userId, 
        startDate.toIso8601String(), 
        endDate.toIso8601String()
      ]);

      return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }
}
