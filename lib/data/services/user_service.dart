import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintrack_apps/data/database_helper.dart';
import 'package:fintrack_apps/data/services/service_data.dart';

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FinancialService _financialService = FinancialService();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Get current user ID from local database
  Future<int?> getCurrentUserId() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) return null;

    final localUser = await _dbHelper.getUserByFirebaseUid(firebaseUser.uid);
    return localUser?['id'] as int?;
  }

  // Initialize user in local database after Firebase auth
  Future<int> initializeUser() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw Exception('No Firebase user found');
    }

    // Insert or update user in local database
    final userId = await _dbHelper.insertOrUpdateUser(
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.displayName,
    );

    // ✅ Buat semua akun default jika user baru
    await _createDefaultAccountsIfNeeded(userId);

    return userId;
  }

  // ✅ Buat semua akun default untuk user baru
  Future<void> _createDefaultAccountsIfNeeded(int userId) async {
    try {
      // Cek apakah user sudah memiliki akun
      final existingAccounts =
          await _financialService.getUserAccountsWithDetails(userId);

      if (existingAccounts.isEmpty) {
        print('=== CREATING DEFAULT ACCOUNTS FOR USER $userId ===');

        // Ambil semua account types yang tersedia
        final accountTypes = await _financialService.getAccountTypes();

        print('Available account types: ${accountTypes.length}');

        // Buat akun untuk setiap account type
        for (final accountType in accountTypes) {
          print(
              'Creating account for: ${accountType.name} (ID: ${accountType.id})');

          await _financialService.createUserAccount(
            userId: userId,
            accountTypeId: accountType.id!, // ✅ Gunakan ID dari account_types
            initialBalance: 0.0,
          );
        }

        print('=== DEFAULT ACCOUNTS CREATED SUCCESSFULLY ===');
      } else {
        print('User already has ${existingAccounts.length} accounts');
      }
    } catch (e) {
      print('Error creating default accounts: $e');
      // Jangan throw error, biarkan user bisa login walaupun ada masalah
    }
  }

  // Get user data from local database
  Future<Map<String, dynamic>?> getUserData() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) return null;

    return await _dbHelper.getUserByFirebaseUid(firebaseUser.uid);
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Method untuk reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ✅ Method untuk update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }

  // ✅ Method untuk verifikasi kepemilikan transaksi
  Future<bool> verifyTransactionOwnership(int transactionId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;

    return await _dbHelper.verifyTransactionOwnership(transactionId, userId);
  }

  // ✅ Method untuk mendapatkan statistik transaksi user
  Future<Map<String, dynamic>> getUserTransactionStats() async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      return {
        'total_transactions': 0,
        'total_income': 0.0,
        'total_expense': 0.0,
        'net_balance': 0.0,
      };
    }

    return await _dbHelper.getTransactionStats(userId);
  }

  // ✅ Method untuk mendapatkan detail transaksi dengan verifikasi
  Future<Map<String, dynamic>?> getTransactionDetails(int transactionId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    // Verifikasi kepemilikan
    final isOwner = await verifyTransactionOwnership(transactionId);
    if (!isOwner) return null;

    return await _dbHelper.getTransactionWithAccountDetails(transactionId);
  }

  // ✅ Method untuk validasi user session
  Future<bool> validateUserSession() async {
    try {
      final firebaseUser = currentUser;
      if (firebaseUser == null) return false;

      // Cek apakah user masih valid di database lokal
      final localUser = await _dbHelper.getUserByFirebaseUid(firebaseUser.uid);
      return localUser != null;
    } catch (e) {
      print('Error validating user session: $e');
      return false;
    }
  }

  // ✅ Method untuk debug - cek akun user
  Future<void> debugUserAccounts() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      final accounts =
          await _financialService.getUserAccountsWithDetails(userId);
      print('=== DEBUG USER ACCOUNTS ===');
      print('User ID: $userId');
      print('Total accounts: ${accounts.length}');

      for (int i = 0; i < accounts.length; i++) {
        final account = accounts[i]['account'];
        final accountType = accounts[i]['accountType'];
        print(
            'Account $i: ${accountType.name} (ID: ${account.id}, Balance: ${account.balance})');
      }
    }
  }

  // ✅ Method untuk debug - cek transaksi user
  Future<void> debugUserTransactions() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      final transactions =
          await _financialService.getTransactionHistory(userId);
      print('=== DEBUG USER TRANSACTIONS ===');
      print('User ID: $userId');
      print('Total transactions: ${transactions.length}');

      for (int i = 0; i < transactions.length && i < 5; i++) {
        final transaction = transactions[i];
        print(
            'Transaction $i: ${transaction.description} - ${transaction.type} - ${transaction.amount}');
      }
    }
  }

  // ✅ Method untuk mendapatkan ringkasan akun user
  Future<Map<String, dynamic>> getUserAccountSummary() async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      return {
        'total_balance': 0.0,
        'total_accounts': 0,
        'accounts': [],
      };
    }

    final accounts = await _financialService.getUserAccountsWithDetails(userId);
    final totalBalance = await _financialService.getTotalBalance(userId);

    return {
      'total_balance': totalBalance,
      'total_accounts': accounts.length,
      'accounts': accounts,
    };
  }

  // ✅ Method untuk logout dengan cleanup
  Future<void> signOutWithCleanup() async {
    try {
      // Lakukan cleanup jika diperlukan
      await _dbHelper.closeDatabase();
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      // Tetap coba logout Firebase meskipun ada error
      await _auth.signOut();
    }
  }
}
