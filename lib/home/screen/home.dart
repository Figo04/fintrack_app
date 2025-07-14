import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/data/services/user_service.dart';
import 'package:fintrack_apps/budget/screen/pendapatan.dart';
import 'package:fintrack_apps/budget/screen/pengeluaran.dart';
import 'package:fintrack_apps/core/themes/color.dart';
import 'package:fintrack_apps/features/auth/screen/login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FinancialService _financialService = FinancialService();
  final UserService _userService = UserService();

  int? _currentUserId;
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _userAccounts = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is logged in
      if (!_userService.isLoggedIn) {
        _navigateToLogin();
        return;
      }

      // Initialize user in local database
      final userId = await _userService.initializeUser();
      final userData = await _userService.getUserData();

      setState(() {
        _currentUserId = userId;
        _userName = userData?['username'] ?? '';
      });

      // Load financial data
      await _loadData();
    } catch (e) {
      print('Error initializing user: $e');
      _navigateToLogin();
    }
  }

  Future<void> _loadData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final totalBalance =
          await _financialService.getTotalBalance(_currentUserId!);
      final userAccounts =
          await _financialService.getUserAccountsWithDetails(_currentUserId!);
      final totalIncome =
          await _financialService.getTotalIncome(_currentUserId!);
      final totalExpense =
          await _financialService.getTotalExpense(_currentUserId!);
      final transactions =
          await _financialService.getTransactionHistory(_currentUserId!);

      setState(() {
        _totalBalance = totalBalance;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _userAccounts = userAccounts;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _refreshData() => _loadData();

  Future<void> _signOut() async {
    try {
      await _userService.signOut();
      _navigateToLogin();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ✅ Method untuk menghapus transaksi
  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Panggil service untuk menghapus transaksi
      final result = await _financialService.deleteTransaction(
        transactionId: transaction.id!,
        userId: _currentUserId!,
      );

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh data
        await _loadData();
      } else {
        // Tampilkan error dan kembalikan item ke posisi semula
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus transaksi: ${result['error']}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Tutup loading dialog jika masih terbuka
      Navigator.of(context).pop();

      print('Error deleting transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if user is not initialized
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FinTrack', style: TextStyle(color: AppColors.white)),
            Text(
              "Hai $_userName",
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Saldo
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Saldo',
                        style: TextStyle(color: AppColors.white, fontSize: 16),
                      ),
                      Text(
                        FinancialService.formatCurrency(_totalBalance),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Summary Income & Expense
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem("Pemasukan",
                          FinancialService.formatCurrency(_totalIncome),
                          isPositive: true),
                      _buildSummaryItem("Pengeluaran",
                          FinancialService.formatCurrency(_totalExpense)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Header Riwayat Transaksi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_transactions.length} transaksi',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Daftar Transaksi dengan fitur swipe to delete
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/icon_1.png',
                                  width: 300, height: 300),
                              const SizedBox(height: 15),
                              const Text('Tidak ada data transaksi',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Mulai tambahkan pendapatan atau pengeluaran',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final isIncome =
                                transaction.type == TransactionType.income;

                            // ✅ Wrap ListTile dengan Dismissible untuk swipe to delete
                            // ✅ Perbaikan untuk menampilkan animasi swipe
                            return Dismissible(
                              key: Key(transaction.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                // ✅ Tampilkan dialog konfirmasi
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Hapus Transaksi'),
                                          content: Text(
                                            'Apakah Anda yakin ingin menghapus transaksi "${transaction.description}"?\n\n'
                                            'Saldo akan dikembalikan ke kondisi sebelum transaksi ini.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false; // ✅ Return hasil dialog, bukan selalu false
                              },
                              onDismissed: (direction) async {
                                // ✅ Proses penghapusan setelah konfirmasi
                                await _deleteTransaction(transaction);
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isIncome
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      color:
                                          isIncome ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.account_balance_wallet,
                                              size: 14,
                                              color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _getAccountName(
                                                  transaction.accountId),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateDetailed(
                                                transaction.createdAt),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      if (transaction.category.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Text(
                                              transaction.category,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isIncome ? '+' : '-'}${FinancialService.formatCurrency(transaction.amount)}',
                                        style: TextStyle(
                                            color: isIncome
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(isIncome ? 'Masuk' : 'Keluar',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.add_event,
        animatedIconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.third,
        overlayOpacity: 0.1,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.remove_shopping_cart),
            backgroundColor: AppColors.fourty,
            label: 'Pengeluaran',
            labelStyle: const TextStyle(fontSize: 14),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PengeluaranScreen(
                          userId: _currentUserId!,
                        )),
              );
              if (result == true) _refreshData();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.attach_money),
            backgroundColor: AppColors.fivety,
            label: 'Pendapatan',
            labelStyle: const TextStyle(fontSize: 14),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PendapatanScreen(userId: _currentUserId!)),
              );
              if (result == true) _refreshData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount,
      {bool isPositive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateDetailed(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final dateStr = (dateOnly == today)
        ? 'Hari ini'
        : (dateOnly == yesterday)
            ? 'Kemarin'
            : DateFormat('dd MMM yyyy', 'id_ID').format(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr, $timeStr';
  }

  String _getAccountName(int accountId) {
    try {
      final accountMap =
          _userAccounts.firstWhere((acc) => acc['account'].id == accountId);
      final accountType = accountMap['accountType'] as AccountType;
      return accountType.name;
    } catch (_) {
      return 'Akun Tidak Diketahui';
    }
  }
}
