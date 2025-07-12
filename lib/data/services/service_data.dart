import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/data/repositories/repo_data.dart';

class FinancialService {
  final FinancialRepository _repository = FinancialRepository();

  // Get account types
  Future<List<AccountType>> getAccountTypes() async {
    return await _repository.getAccountTypes();
  }

  // Get total balance
  Future<double> getTotalBalance(int userId) async {
    final accounts = await _repository.getUserAccounts(userId);
    double total = 0.0;

    for (final account in accounts) {
      total += account.balance;
    }

    return total;
  }

  // Add income
  Future<Map<String, dynamic>> addIncome({
    required int userId,
    required int accountId,
    required double amount,
    required String description,
    String category = 'Income',
  }) async {
    try {
      final account = await _repository.getUserAccount(userId, accountId);
      if (account == null) {
        throw Exception('Akun tidak ditemukan');
      }

      final transaction = Transaction(
        userId: userId,
        accountId: accountId,
        type: TransactionType.income, // ✅ Gunakan enum
        amount: amount,
        description: description,
        category: category,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _repository.insertTransaction(transaction);

      final updatedAccount = account.copyWith(
        balance: account.balance + amount,
        updatedAt: DateTime.now(),
      );
      await _repository.updateUserAccount(updatedAccount);

      return {
        'success': true,
        'newBalance': updatedAccount.balance,
        'totalBalance': await getTotalBalance(userId),
      };
    } catch (e) {
      print('Error in addIncome: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add expense
  Future<Map<String, dynamic>> addExpense({
    required int userId,
    required int accountId,
    required double amount,
    required String description,
    String category = 'Expense',
  }) async {
    try {
      final account = await _repository.getUserAccount(userId, accountId);
      if (account == null) {
        throw Exception('Akun tidak ditemukan');
      }

      if (account.balance < amount) {
        throw Exception('Saldo tidak mencukupi');
      }

      final transaction = Transaction(
        userId: userId,
        accountId: accountId,
        type: TransactionType.expense, // ✅ Gunakan enum
        amount: amount,
        description: description,
        category: category,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _repository.insertTransaction(transaction);

      final updatedAccount = account.copyWith(
        balance: account.balance - amount,
        updatedAt: DateTime.now(),
      );
      await _repository.updateUserAccount(updatedAccount);

      return {
        'success': true,
        'newBalance': updatedAccount.balance,
        'totalBalance': await getTotalBalance(userId),
      };
    } catch (e) {
      print('Error in addExpense: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get user accounts with details
  Future<List<Map<String, dynamic>>> getUserAccountsWithDetails(
      int userId) async {
    return await _repository.getUserAccountsWithDetails(userId);
  }

  // Total income
  Future<double> getTotalIncome(int userId) async {
    return await _repository.getTotalIncome(userId);
  }

  // Total expense
  Future<double> getTotalExpense(int userId) async {
    return await _repository.getTotalExpense(userId);
  }

  // Get transaction history
  Future<List<Transaction>> getTransactionHistory(int userId) async {
    final transactions = await _repository.getTransactions(userId);

    // Debug log
    print('=== DEBUG TRANSACTION HISTORY ===');
    print('Total transactions: ${transactions.length}');
    for (int i = 0; i < transactions.length && i < 3; i++) {
      print(
          'Transaction $i: type="${transactions[i].type}", amount=${transactions[i].amount}');
    }

    return transactions;
  }

  // Create new user account
  Future<int> createUserAccount({
    required int userId,
    required int accountTypeId,
    double initialBalance = 0.0,
  }) async {
    final account = UserAccount(
      userId: userId,
      accountTypeId: accountTypeId,
      balance: initialBalance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _repository.insertUserAccount(account);
  }

  // Format currency
  static String formatCurrency(double amount) {
    return 'IDR ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}
