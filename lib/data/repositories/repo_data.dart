import 'package:fintrack_apps/data/database_helper.dart';
import 'package:fintrack_apps/data/models/model_data.dart';

class FinancialRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Account Types
  Future<List<AccountType>> getAccountTypes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('account_types');
    return List.generate(maps.length, (i) => AccountType.fromMap(maps[i]));
  }

  // User Accounts
  Future<int> insertUserAccount(UserAccount account) async {
    final db = await _dbHelper.database;
    return await db.insert('user_accounts', account.toMap());
  }

  Future<List<UserAccount>> getUserAccounts(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => UserAccount.fromMap(maps[i]));
  }

  Future<UserAccount?> getUserAccount(int userId, int accountId) async {
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
  }

  Future<void> updateUserAccount(UserAccount account) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // Transactions
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getTransactions(int userId,
      {int limit = 50}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // Get user accounts with account type details
  Future<List<Map<String, dynamic>>> getUserAccountsWithDetails(
      int userId) async {
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
  }

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

// Method untuk mendapatkan total expense user
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

// Method untuk mendapatkan semua transaksi user (opsional)
  Future<List<Transaction>> getUserTransactions(int userId,
      {int limit = 50}) async {
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
}
