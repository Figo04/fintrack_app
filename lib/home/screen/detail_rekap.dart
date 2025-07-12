import 'package:fintrack_apps/core/themes/color.dart';
import 'package:flutter/material.dart';

import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DetailRekapPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final List<Transaction> transactions;

  const DetailRekapPage({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.transactions,
  }) : super(key: key);

  @override
  State<DetailRekapPage> createState() => _DetailRekapPageState();
}

class _DetailRekapPageState extends State<DetailRekapPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
            const Text('Detail Rekap', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Grafik'),
                Tab(text: 'Kategori'),
                Tab(text: 'Judul'),
              ],
            ),
          ),

          // Date Range
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${DateFormat('dd MMM yyyy').format(widget.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.endDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrafikTab(),
                _buildKategoriTab(),
                _buildJudulTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafikTab() {
    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.cyan,
      Colors.brown,
    ];

    int colorIndex = 0;

    // Add expense categories
    widget.expenseByCategory.forEach((category, amount) {
      double percentage = (amount / widget.totalExpense) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pie Chart
          Container(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 60,
                sectionsSpace: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Legend
          ...widget.expenseByCategory.entries.map((entry) {
            double percentage = (entry.value / widget.totalExpense) * 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors[widget.expenseByCategory.keys
                              .toList()
                              .indexOf(entry.key) %
                          colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    _formatCurrency(entry.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildKategoriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary
          _buildSummarySection(),

          const SizedBox(height: 20),

          // Pengeluaran per kategori
          if (widget.expenseByCategory.isNotEmpty) ...[
            const Text(
              'Pengeluaran per Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.expenseByCategory.entries.map((entry) {
              double percentage = (entry.value / widget.totalExpense) * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatCurrency(entry.value),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.secondary!),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 20),

          // Pemasukan per kategori
          if (widget.incomeByCategory.isNotEmpty) ...[
            const Text(
              'Pemasukan per Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.incomeByCategory.entries.map((entry) {
              double percentage = (entry.value / widget.totalIncome) * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatCurrency(entry.value),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.secondary!),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildJudulTab() {
    // Group transactions by date
    Map<String, List<Transaction>> transactionsByDate = {};

    for (final transaction in widget.transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!transactionsByDate.containsKey(dateKey)) {
        transactionsByDate[dateKey] = [];
      }
      transactionsByDate[dateKey]!.add(transaction);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: transactionsByDate.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(entry.key)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value.map((transaction) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: transaction.type == TransactionType.income
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            transaction.type == TransactionType.income
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: transaction.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${transaction.type == TransactionType.income ? '+' : '-'} ${_formatCurrency(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transaction.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummarySection() {
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
          _buildSummaryRow('Pengeluaran', widget.totalExpense, Colors.red),
          const Divider(),
          _buildSummaryRow('Pemasukan', widget.totalIncome, Colors.green),
          const Divider(),
          _buildSummaryRow('Total Saldo', widget.totalBalance, Colors.blue),
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
            color: color,
          ),
        ),
      ],
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
