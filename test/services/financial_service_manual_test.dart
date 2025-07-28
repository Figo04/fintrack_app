import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/data/repositories/repo_data.dart';
import 'package:fintrack_apps/data/services/service_data.dart';

// Enhanced Manual Mock Repository dengan error handling yang lebih baik
class MockFinancialRepository implements FinancialRepository {
  // Store untuk menyimpan data mock
  final Map<String, dynamic> _mockData = {};
  final List<String> _calledMethods = []; // ✅ String, bukan Function
  final Map<String, int> _methodCallCounts = {};
  
  // Helper methods untuk setup test data
  void setupMockUserAccount(int userId, int accountId, UserAccount account) {
    _mockData['user_account_${userId}_$accountId'] = account;
  }
  
  void setupMockGetUserAccounts(int userId, List<UserAccount> accounts) {
    _mockData['user_accounts_$userId'] = accounts;
  }
  
  void throwOnMethod(String methodName) {
    _mockData['throw_$methodName'] = true;
  }
  
  void clearMockData() {
    _mockData.clear();
    _calledMethods.clear();
    _methodCallCounts.clear();
  }
  
  // Enhanced verification methods
  bool wasMethodCalled(String methodName) {
    return _calledMethods.any((call) => call.contains(methodName));
  }

  int getMethodCallCount(String methodName) {
    return _methodCallCounts[methodName] ?? 0;
  }

  List<String> getCalledMethods() {
    return List.from(_calledMethods);
  }

  // Helper untuk tracking method calls
  void _trackMethodCall(String methodName, [Map<String, dynamic>? params]) {
    final callString = params != null 
        ? '$methodName(${params.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
        : methodName;
    
    _calledMethods.add(callString);
    _methodCallCounts[methodName] = (_methodCallCounts[methodName] ?? 0) + 1;
  }

  @override
  Future<UserAccount?> getUserAccount(int userId, int accountId) async {
    _trackMethodCall('getUserAccount', {'userId': userId, 'accountId': accountId});
    
    if (_mockData['throw_getUserAccount'] == true) {
      throw Exception('Mock database error in getUserAccount');
    }
    
    return _mockData['user_account_${userId}_$accountId'] as UserAccount?;
  }

  @override
  Future<List<UserAccount>> getUserAccounts(int userId) async {
    _trackMethodCall('getUserAccounts', {'userId': userId});
    
    if (_mockData['throw_getUserAccounts'] == true) {
      throw Exception('Mock database error in getUserAccounts');
    }
    
    return (_mockData['user_accounts_$userId'] as List<UserAccount>?) ?? [];
  }

  @override
  Future<int> insertTransaction(Transaction transaction) async {
    _trackMethodCall('insertTransaction', {
      'userId': transaction.userId,
      'accountId': transaction.accountId,
      'type': transaction.type.toString(),
      'amount': transaction.amount,
    });
    
    if (_mockData['throw_insertTransaction'] == true) {
      throw Exception('Mock database error in insertTransaction');
    }
    
    // Store transaction untuk verifikasi
    _mockData['last_inserted_transaction'] = transaction;
    return 1; // Mock transaction ID
  }

  @override
  Future<void> updateUserAccount(UserAccount account) async {
    _trackMethodCall('updateUserAccount', {
      'accountId': account.id,
      'userId': account.userId,
      'balance': account.balance,
    });
    
    if (_mockData['throw_updateUserAccount'] == true) {
      throw Exception('Mock database error in updateUserAccount');
    }
    
    // Update mock data untuk konsistensi
    _mockData['user_account_${account.userId}_${account.id}'] = account;
    _mockData['last_updated_account'] = account;
  }

  // Verification helpers untuk detailed testing
  Transaction? getLastInsertedTransaction() {
    return _mockData['last_inserted_transaction'] as Transaction?;
  }

  UserAccount? getLastUpdatedAccount() {
    return _mockData['last_updated_account'] as UserAccount?;
  }

  // Implement semua method interface lainnya dengan default behavior
  @override
  Future<List<AccountType>> getAccountTypes() async {
    _trackMethodCall('getAccountTypes');
    return [];
  }

  @override
  Future<int> insertUserAccount(UserAccount account) async {
    _trackMethodCall('insertUserAccount');
    return 1;
  }

  @override
  Future<List<Transaction>> getTransactions(int userId, {int limit = 50}) async {
    _trackMethodCall('getTransactions', {'userId': userId, 'limit': limit});
    return [];
  }

  @override
  Future<Transaction?> getTransactionById(int transactionId) async {
    _trackMethodCall('getTransactionById', {'transactionId': transactionId});
    return null;
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {
    _trackMethodCall('deleteTransaction', {'transactionId': transactionId});
  }

  @override
  Future<List<Map<String, dynamic>>> getUserAccountsWithDetails(int userId) async {
    _trackMethodCall('getUserAccountsWithDetails', {'userId': userId});
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionsWithAccountDetails(int userId, {int limit = 50}) async {
    _trackMethodCall('getTransactionsWithAccountDetails', {'userId': userId, 'limit': limit});
    return [];
  }

  @override
  Future<List<Transaction>> getUserTransactions(int userId, {int limit = 50}) async {
    _trackMethodCall('getUserTransactions', {'userId': userId, 'limit': limit});
    return [];
  }

  @override
  Future<double> getTotalIncome(int userId) async {
    _trackMethodCall('getTotalIncome', {'userId': userId});
    return 0.0;
  }

  @override
  Future<double> getTotalExpense(int userId) async {
    _trackMethodCall('getTotalExpense', {'userId': userId});
    return 0.0;
  }

  @override
  Future<double> getNetBalance(int userId) async {
    _trackMethodCall('getNetBalance', {'userId': userId});
    return 0.0;
  }

  @override
  Future<Map<String, double>> getFinancialSummary(int userId) async {
    _trackMethodCall('getFinancialSummary', {'userId': userId});
    return {};
  }

  @override
  Future<bool> verifyTransactionOwnership(int transactionId, int userId) async {
    _trackMethodCall('verifyTransactionOwnership', {'transactionId': transactionId, 'userId': userId});
    return true;
  }

  @override
  Future<bool> verifyAccountOwnership(int accountId, int userId) async {
    _trackMethodCall('verifyAccountOwnership', {'accountId': accountId, 'userId': userId});
    return true;
  }

  @override
  Future<Map<String, double>> getExpenseByCategory(int userId) async {
    _trackMethodCall('getExpenseByCategory', {'userId': userId});
    return {};
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(int userId, DateTime startDate, DateTime endDate) async {
    _trackMethodCall('getTransactionsByDateRange', {
      'userId': userId, 
      'startDate': startDate.toIso8601String(), 
      'endDate': endDate.toIso8601String()
    });
    return [];
  }
}

void main() {
  group('FinancialService Tests (Enhanced Manual Mock)', () {
    late FinancialService financialService;
    late MockFinancialRepository mockRepository;

    // Test data
    const testUserId = 1;
    const testAccountId = 1;
    const testAmount = 100000.0;
    const testDescription = 'Test transaction';
    const testCategory = 'Test Category';

    late UserAccount testUserAccount;

    setUp(() {
      mockRepository = MockFinancialRepository();
      financialService = FinancialService(repository: mockRepository);
      mockRepository.clearMockData();
      
      testUserAccount = UserAccount(
        id: testAccountId,
        userId: testUserId,
        accountTypeId: 1,
        balance: 500000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('addIncome Tests', () {
      test('should successfully add income and update account balance', () async {
        // Arrange
        mockRepository.setupMockUserAccount(testUserId, testAccountId, testUserAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [
          testUserAccount.copyWith(balance: testUserAccount.balance + testAmount)
        ]);

        // Act
        final result = await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], true);
        expect(result['newBalance'], testUserAccount.balance + testAmount);
        expect(result.containsKey('totalBalance'), true);

        // Enhanced verification
        expect(mockRepository.wasMethodCalled('getUserAccount'), true);
        expect(mockRepository.wasMethodCalled('insertTransaction'), true);
        expect(mockRepository.wasMethodCalled('updateUserAccount'), true);
        expect(mockRepository.getMethodCallCount('getUserAccount'), 1);
        expect(mockRepository.getMethodCallCount('insertTransaction'), 1);
        expect(mockRepository.getMethodCallCount('updateUserAccount'), 1);

        // Verify transaction details
        final insertedTransaction = mockRepository.getLastInsertedTransaction();
        expect(insertedTransaction, isNotNull);
        expect(insertedTransaction!.userId, testUserId);
        expect(insertedTransaction.accountId, testAccountId);
        expect(insertedTransaction.type, TransactionType.income);
        expect(insertedTransaction.amount, testAmount);
        expect(insertedTransaction.description, testDescription);
        expect(insertedTransaction.category, testCategory);

        // Verify account update
        final updatedAccount = mockRepository.getLastUpdatedAccount();
        expect(updatedAccount, isNotNull);
        expect(updatedAccount!.balance, testUserAccount.balance + testAmount);
      });

      test('should return error when account not found', () async {
        // Arrange - tidak setup mock account (akan return null)

        // Act
        final result = await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], false);
        expect(result['error'], contains('Akun tidak ditemukan'));

        // Verify method calls
        expect(mockRepository.wasMethodCalled('getUserAccount'), true);
        expect(mockRepository.wasMethodCalled('insertTransaction'), false);
        expect(mockRepository.wasMethodCalled('updateUserAccount'), false);
        expect(mockRepository.getMethodCallCount('getUserAccount'), 1);
        expect(mockRepository.getMethodCallCount('insertTransaction'), 0);
        expect(mockRepository.getMethodCallCount('updateUserAccount'), 0);
      });

      test('should handle repository exception', () async {
        // Arrange
        mockRepository.throwOnMethod('getUserAccount');

        // Act
        final result = await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], false);
        expect(result['error'], contains('Mock database error'));
        expect(mockRepository.wasMethodCalled('getUserAccount'), true);
      });
    });

    group('addExpense Tests', () {
      test('should successfully add expense and update account balance', () async {
        // Arrange
        mockRepository.setupMockUserAccount(testUserId, testAccountId, testUserAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [
          testUserAccount.copyWith(balance: testUserAccount.balance - testAmount)
        ]);

        // Act
        final result = await financialService.addExpense(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], true);
        expect(result['newBalance'], testUserAccount.balance - testAmount);
        expect(result.containsKey('totalBalance'), true);

        // Enhanced verification
        expect(mockRepository.wasMethodCalled('getUserAccount'), true);
        expect(mockRepository.wasMethodCalled('insertTransaction'), true);
        expect(mockRepository.wasMethodCalled('updateUserAccount'), true);

        // Verify transaction details
        final insertedTransaction = mockRepository.getLastInsertedTransaction();
        expect(insertedTransaction, isNotNull);
        expect(insertedTransaction!.type, TransactionType.expense);
        expect(insertedTransaction.amount, testAmount);

        // Verify account balance decreased
        final updatedAccount = mockRepository.getLastUpdatedAccount();
        expect(updatedAccount, isNotNull);
        expect(updatedAccount!.balance, testUserAccount.balance - testAmount);
      });

      test('should return error when insufficient balance', () async {
        // Arrange
        final lowBalanceAccount = testUserAccount.copyWith(balance: 50000.0);
        mockRepository.setupMockUserAccount(testUserId, testAccountId, lowBalanceAccount);

        // Act
        final result = await financialService.addExpense(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount, // 100000.0 > 50000.0
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], false);
        expect(result['error'], contains('Saldo tidak mencukupi'));

        // Verify no updates were made
        expect(mockRepository.wasMethodCalled('getUserAccount'), true);
        expect(mockRepository.wasMethodCalled('insertTransaction'), false);
        expect(mockRepository.wasMethodCalled('updateUserAccount'), false);
        expect(mockRepository.getLastInsertedTransaction(), isNull);
        expect(mockRepository.getLastUpdatedAccount(), isNull);
      });

      test('should allow expense exactly equal to balance', () async {
        // Arrange
        final exactBalanceAccount = testUserAccount.copyWith(balance: testAmount);
        mockRepository.setupMockUserAccount(testUserId, testAccountId, exactBalanceAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [
          exactBalanceAccount.copyWith(balance: 0.0)
        ]);

        // Act
        final result = await financialService.addExpense(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], true);
        expect(result['newBalance'], 0.0);

        // Verify account balance is exactly 0
        final updatedAccount = mockRepository.getLastUpdatedAccount();
        expect(updatedAccount!.balance, 0.0);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle zero amount transactions', () async {
        // Arrange
        mockRepository.setupMockUserAccount(testUserId, testAccountId, testUserAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [testUserAccount]);

        // Act
        final incomeResult = await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: 0.0,
          description: testDescription,
          category: testCategory,
        );

        final expenseResult = await financialService.addExpense(
          userId: testUserId,
          accountId: testAccountId,
          amount: 0.0,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(incomeResult['success'], true);
        expect(expenseResult['success'], true);
        expect(mockRepository.getMethodCallCount('insertTransaction'), 2);
      });

      test('should handle very large amounts', () async {
        // Arrange
        const largeAmount = 999999999.99;
        mockRepository.setupMockUserAccount(testUserId, testAccountId, testUserAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [
          testUserAccount.copyWith(balance: testUserAccount.balance + largeAmount)
        ]);

        // Act
        final result = await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: largeAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert
        expect(result['success'], true);
        expect(result['newBalance'], testUserAccount.balance + largeAmount);
      });

      test('should provide detailed call tracking for debugging', () async {
        // Arrange
        mockRepository.setupMockUserAccount(testUserId, testAccountId, testUserAccount);
        mockRepository.setupMockGetUserAccounts(testUserId, [testUserAccount]);

        // Act
        await financialService.addIncome(
          userId: testUserId,
          accountId: testAccountId,
          amount: testAmount,
          description: testDescription,
          category: testCategory,
        );

        // Assert - verify detailed call tracking
        final calledMethods = mockRepository.getCalledMethods();
        expect(calledMethods.length, greaterThan(0));
        
        // Print for debugging (uncomment if needed)
        // print('All called methods:');
        // for (final method in calledMethods) {
        //   print('  - $method');
        // }
      });
    });
  });
}