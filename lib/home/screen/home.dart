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

/**
 * HomeScreen - Layar utama aplikasi FinTrack
 * 
 * Layar ini menampilkan dashboard utama yang berisi:
 * - Header dengan saldo total pengguna
 * - Summary pemasukan dan pengeluaran
 * - Daftar riwayat transaksi dengan fitur swipe-to-delete
 * - Floating Action Button untuk menambah transaksi baru
 * 
 * Fitur utama:
 * - Autentikasi pengguna dan pengelolaan sesi
 * - Real-time data finansial
 * - Hapus transaksi dengan gesture swipe
 * - Navigasi ke form tambah pendapatan/pengeluaran
 * - Logout functionality
 */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===== SERVICES =====
  /// Service untuk mengelola data finansial (transaksi, akun, saldo)
  final FinancialService _financialService = FinancialService();
  
  /// Service untuk mengelola data dan autentikasi pengguna
  final UserService _userService = UserService();

  // ===== STATE VARIABLES =====
  /// ID pengguna yang sedang login
  int? _currentUserId;
  
  /// Total saldo semua akun pengguna
  double _totalBalance = 0.0;
  
  /// Total pemasukan pengguna
  double _totalIncome = 0.0;
  
  /// Total pengeluaran pengguna
  double _totalExpense = 0.0;
  
  /// Daftar akun pengguna beserta detailnya
  List<Map<String, dynamic>> _userAccounts = [];
  
  /// Daftar semua transaksi pengguna
  List<Transaction> _transactions = [];
  
  /// Status loading untuk menampilkan indikator loading
  bool _isLoading = true;
  
  /// Nama pengguna untuk ditampilkan di header
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // ===== USER MANAGEMENT =====
  
  /**
   * Inisialisasi pengguna dan memuat data awal
   * 
   * Proses:
   * 1. Cek status login pengguna
   * 2. Jika belum login, arahkan ke halaman login
   * 3. Jika sudah login, inisialisasi user di database lokal
   * 4. Muat semua data finansial
   * 
   * @throws Exception jika terjadi error dalam proses inisialisasi
   */
  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);

    try {
      // Cek apakah pengguna sudah login
      if (!_userService.isLoggedIn) {
        _navigateToLogin();
        return;
      }

      // Inisialisasi pengguna di database lokal
      final userId = await _userService.initializeUser();
      final userData = await _userService.getUserData();

      setState(() {
        _currentUserId = userId;
        _userName = userData?['username'] ?? '';
      });

      // Muat data finansial
      await _loadData();
    } catch (e) {
      print('Error initializing user: $e');
      _navigateToLogin();
    }
  }

  /**
   * Memuat semua data finansial pengguna
   * 
   * Data yang dimuat:
   * - Total saldo dari semua akun
   * - Detail semua akun pengguna
   * - Total pemasukan dan pengeluaran
   * - Riwayat semua transaksi
   * 
   * @throws Exception jika terjadi error dalam proses loading data
   */
  Future<void> _loadData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // Muat semua data finansial secara paralel untuk performa yang lebih baik
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

  /**
   * Navigasi ke halaman login dengan menghapus semua route sebelumnya
   * Digunakan saat logout atau jika pengguna belum terautentikasi
   */
  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /**
   * Refresh data finansial
   * Dipanggil setelah ada perubahan data (tambah/hapus transaksi)
   */
  void _refreshData() => _loadData();

  /**
   * Proses logout pengguna
   * Menghapus sesi pengguna dan kembali ke halaman login
   */
  Future<void> _signOut() async {
    try {
      await _userService.signOut();
      _navigateToLogin();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ===== TRANSACTION MANAGEMENT =====
  
  /**
   * Menghapus transaksi dengan konfirmasi pengguna
   * 
   * Proses:
   * 1. Tampilkan loading dialog
   * 2. Panggil service untuk menghapus transaksi
   * 3. Tampilkan hasil (sukses/error) dengan SnackBar
   * 4. Refresh data jika berhasil
   * 
   * @param transaction Transaksi yang akan dihapus
   * @throws Exception jika terjadi error dalam proses penghapusan
   */
  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Hapus transaksi melalui service
      final result = await _financialService.deleteTransaction(
        transactionId: transaction.id!,
        userId: _currentUserId!,
      );

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh data untuk menampilkan perubahan
        await _loadData();
      } else {
        // Tampilkan pesan error
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

  // ===== UI BUILD METHODS =====
  
  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika pengguna belum terinisialisasi
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      
      // ===== APP BAR =====
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
      
      // ===== BODY =====
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Saldo Total
                _buildBalanceHeader(),

                // Summary Pemasukan & Pengeluaran
                _buildSummarySection(),
                
                const SizedBox(height: 16),

                // Header Riwayat Transaksi
                _buildTransactionHeader(),
                
                const SizedBox(height: 8),

                // Daftar Transaksi dengan fitur swipe to delete
                _buildTransactionList(),
              ],
            ),
      
      // ===== FLOATING ACTION BUTTON =====
      floatingActionButton: _buildSpeedDial(),
    );
  }

  /**
   * Membangun widget header saldo total
   * Menampilkan saldo total dengan background gradient
   */
  Widget _buildBalanceHeader() {
    return Container(
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
    );
  }

  /**
   * Membangun widget section summary pemasukan dan pengeluaran
   * Menampilkan total pemasukan dan pengeluaran dalam card terpisah
   */
  Widget _buildSummarySection() {
    return Container(
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
    );
  }

  /**
   * Membangun widget header untuk section riwayat transaksi
   * Menampilkan judul dan jumlah transaksi
   */
  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_transactions.length} transaksi',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /**
   * Membangun widget daftar transaksi
   * Menampilkan empty state jika tidak ada transaksi, atau ListView dengan fitur swipe-to-delete
   */
  Widget _buildTransactionList() {
    return Expanded(
      child: _transactions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(_transactions[index]);
              },
            ),
    );
  }

  /**
   * Membangun widget empty state ketika tidak ada transaksi
   * Menampilkan gambar, pesan, dan instruksi untuk pengguna
   */
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/icon_1.png', width: 300, height: 300),
          const SizedBox(height: 15),
          const Text('Tidak ada data transaksi',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Mulai tambahkan pendapatan atau pengeluaran',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  /**
   * Membangun widget item transaksi dengan fitur swipe-to-delete
   * 
   * @param transaction Data transaksi yang akan ditampilkan
   * @return Widget Dismissible yang dapat di-swipe untuk menghapus
   */
  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;

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
      // Konfirmasi sebelum menghapus
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(transaction);
      },
      // Proses penghapusan setelah konfirmasi
      onDismissed: (direction) async {
        await _deleteTransaction(transaction);
      },
      child: _buildTransactionCard(transaction, isIncome),
    );
  }

  /**
   * Membangun widget card untuk menampilkan detail transaksi
   * 
   * @param transaction Data transaksi
   * @param isIncome Apakah transaksi ini pemasukan
   * @return Widget Card dengan detail transaksi
   */
  Widget _buildTransactionCard(Transaction transaction, bool isIncome) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Icon indikator jenis transaksi
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        // Deskripsi dan detail transaksi
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildTransactionSubtitle(transaction),
        // Jumlah dan jenis transaksi
        trailing: _buildTransactionTrailing(transaction, isIncome),
      ),
    );
  }

  /**
   * Membangun widget subtitle untuk item transaksi
   * Menampilkan nama akun, waktu, dan kategori (jika ada)
   * 
   * @param transaction Data transaksi
   * @return Widget Column dengan detail tambahan
   */
  Widget _buildTransactionSubtitle(Transaction transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // Nama akun
        Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _getAccountName(transaction.accountId),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Waktu transaksi
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              _formatDateDetailed(transaction.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        // Kategori (jika ada)
        if (transaction.category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.category,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
      ],
    );
  }

  /**
   * Membangun widget trailing untuk item transaksi
   * Menampilkan jumlah uang dan jenis transaksi
   * 
   * @param transaction Data transaksi
   * @param isIncome Apakah transaksi ini pemasukan
   * @return Widget Column dengan jumlah dan label
   */
  Widget _buildTransactionTrailing(Transaction transaction, bool isIncome) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${isIncome ? '+' : '-'}${FinancialService.formatCurrency(transaction.amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isIncome ? 'Masuk' : 'Keluar',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  /**
   * Menampilkan dialog konfirmasi penghapusan transaksi
   * 
   * @param transaction Transaksi yang akan dihapus
   * @return Future<bool> true jika pengguna mengkonfirmasi penghapusan
   */
  Future<bool> _showDeleteConfirmation(Transaction transaction) async {
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
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /**
   * Membangun widget SpeedDial untuk floating action button
   * Menyediakan opsi cepat untuk menambah pendapatan atau pengeluaran
   */
  Widget _buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.add_event,
      animatedIconTheme: const IconThemeData(color: AppColors.white),
      backgroundColor: AppColors.third,
      overlayOpacity: 0.1,
      spacing: 12,
      children: [
        // Tombol tambah pengeluaran
        SpeedDialChild(
          child: const Icon(Icons.remove_shopping_cart),
          backgroundColor: AppColors.fourty,
          label: 'Pengeluaran',
          labelStyle: const TextStyle(fontSize: 14),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PengeluaranScreen(userId: _currentUserId!),
              ),
            );
            if (result == true) _refreshData();
          },
        ),
        // Tombol tambah pendapatan
        SpeedDialChild(
          child: const Icon(Icons.attach_money),
          backgroundColor: AppColors.fivety,
          label: 'Pendapatan',
          labelStyle: const TextStyle(fontSize: 14),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendapatanScreen(userId: _currentUserId!),
              ),
            );
            if (result == true) _refreshData();
          },
        ),
      ],
    );
  }

  // ===== HELPER METHODS =====
  
  /**
   * Membangun widget item summary (pemasukan/pengeluaran)
   * 
   * @param title Judul (Pemasukan/Pengeluaran)
   * @param amount Jumlah dalam format currency
   * @param isPositive Apakah nilai ini positif (untuk styling warna)
   * @return Widget dengan styling yang sesuai
   */
  Widget _buildSummaryItem(String title, String amount, {bool isPositive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Format tanggal dengan detail waktu untuk tampilan yang user-friendly
   * 
   * Format:
   * - Hari ini: "Hari ini, HH:mm"
   * - Kemarin: "Kemarin, HH:mm" 
   * - Lainnya: "dd MMM yyyy, HH:mm"
   * 
   * @param date Tanggal yang akan diformat
   * @return String tanggal yang sudah diformat
   */
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

  /**
   * Mendapatkan nama akun berdasarkan ID akun
   * 
   * @param accountId ID akun yang dicari
   * @return String nama akun atau "Akun Tidak Diketahui" jika tidak ditemukan
   */
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