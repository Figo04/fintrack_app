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
}
