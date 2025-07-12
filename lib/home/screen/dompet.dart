import 'package:fintrack_apps/core/themes/color.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/budget/screen/tambah_saldo.dart';
import 'package:fintrack_apps/data/services/user_service.dart';
import 'package:flutter/material.dart';

class DompetScreen extends StatefulWidget {
  const DompetScreen({super.key});

  @override
  State<DompetScreen> createState() => _DompetScreenState();
}

class _DompetScreenState extends State<DompetScreen> {
  final FinancialService _financialService = FinancialService();
  final UserService _userService = UserService();
  final TextEditingController _amountController = TextEditingController();

  int? _currentUserId;
  double _totalBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);

    try {
      // Initialize user in local database
      final userId = await _userService.initializeUser();

      setState(() {
        _currentUserId = userId;
      });

      // Load financial data
      await _loadData();
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  Future<void> _loadData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final totalBalance =
          await _financialService.getTotalBalance(_currentUserId!);

      setState(() {
        _totalBalance = totalBalance;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _refreshData() => _loadData();
  int selectedIndex = 0; // index icon yang sedang aktif

  final List<Map<String, dynamic>> wallets = [
    {"icon": Icons.account_balance_wallet, "label": "Dana"},
    {"icon": Icons.account_balance, "label": "BCA"},
    {"icon": Icons.account_balance_wallet_outlined, "label": "Gopay"},
    {"icon": Icons.money, "label": "Uang Tunai"},
    {"icon": Icons.account_balance, "label": "BRI"},
    {"icon": Icons.account_balance, "label": "Mandiri"},
    {"icon": Icons.account_balance, "label": "Jago"},
    {"icon": Icons.account_balance, "label": "Jenius"},
    {"icon": Icons.account_balance_wallet, "label": "OVO"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  Icons.account_balance_wallet,
                  size: 24,
                ), // Ganti icon sesuai kebutuhan
                SizedBox(width: 5),
                Text(
                  'Dompet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Container(
            width: double.infinity,
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
            ),
            // total saldo
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Saldo',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  FinancialService.formatCurrency(_totalBalance),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 50),
            margin: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
              ],
            ),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: const EdgeInsets.all(5),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: List.generate(
                wallets.length,
                (index) {
                  final wallet = wallets[index];
                  final isSelected = index == selectedIndex;
                  return buildWalletItem(
                    wallet["icon"],
                    wallet["label"],
                    isSelected,
                    () async {
                      setState(() {
                        selectedIndex = index;
                      });

                      // Navigate ke TambahSaldoScreen dan tunggu hasilnya
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TambahSaldoScreen(
                            walletName: wallet["label"],
                            controller: _amountController,
                          ),
                        ),
                      );

                      // Jika result adalah true, refresh data
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWalletItem(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.third : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.third,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.text : Colors.brown[300],
            ),
          ),
        ],
      ),
    );
  }
}
