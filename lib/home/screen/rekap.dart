import 'package:fintrack_apps/core/themes/color.dart';
import 'package:flutter/material.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/data/services/user_service.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/home/screen/detail_rekap.dart';
import 'package:intl/intl.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({Key? key}) : super(key: key);

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen>
    with TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final UserService _userService = UserService();

  // Data
  double totalIncome = 0;
  double totalExpense = 0;
  double totalBalance = 0;
  List<Transaction> transactions = [];
  Map<String, double> expenseByCategory = {};
  Map<String, double> incomeByCategory = {};
  bool isLoading = true;

  // Date Range
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String selectedPeriod = 'Bulanan';

  @override
  void initState() {
    super.initState();
    _setDateRange();
    _loadData();
  }

  void _setDateRange() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'Realtime':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Bulanan':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = await _userService.getCurrentUserId();
      if (userId != null) {
        // Get all transactions
        final allTransactions =
            await _financialService.getTransactionHistory(userId);

        // Filter transactions by date range
        transactions = allTransactions.where((transaction) {
          return transaction.date
                  .isAfter(startDate.subtract(Duration(days: 1))) &&
              transaction.date.isBefore(endDate.add(Duration(days: 1)));
        }).toList();

        // Calculate totals
        totalIncome = 0;
        totalExpense = 0;
        expenseByCategory.clear();
        incomeByCategory.clear();

        for (final transaction in transactions) {
          if (transaction.type == TransactionType.income) {
            totalIncome += transaction.amount;
            incomeByCategory[transaction.category] =
                (incomeByCategory[transaction.category] ?? 0) +
                    transaction.amount;
          } else if (transaction.type == TransactionType.expense) {
            totalExpense += transaction.amount;
            expenseByCategory[transaction.category] =
                (expenseByCategory[transaction.category] ?? 0) +
                    transaction.amount;
          }
        }

        totalBalance = await _financialService.getTotalBalance(userId);
      }
    } catch (e) {
      print('Error loading rekap data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 10, top: 10, right: 250),
            child: Row(
              children: [
                SizedBox(width: 20),
                Icon(
                  Icons.assessment_outlined,
                  size: 24,
                ), // Ganti icon sesuai kebutuhan
                SizedBox(width: 5),
                Text(
                  'Rekap',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Date Range
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                        ),

                        // Summary Cards
                        _buildSummaryCard(),

                        const SizedBox(height: 16),

                        // Detail Button
                        _buildDetailButton(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Pengeluaran', totalExpense, Colors.red),
          const SizedBox(height: 8),
          _buildSummaryRow('Pemasukan', totalIncome, Colors.green),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Saldo', totalBalance, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: title == 'Pengeluaran'
                ? Colors.red
                : title == 'Pemasukan'
                    ? Colors.green
                    : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailRekapPage(
              startDate: startDate,
              endDate: endDate,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              totalBalance: totalBalance,
              expenseByCategory: expenseByCategory,
              incomeByCategory: incomeByCategory,
              transactions: transactions,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Lihat Detail Rekap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 2,
    ).format(amount);
  }
}
