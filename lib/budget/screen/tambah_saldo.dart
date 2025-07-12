import 'package:fintrack_apps/core/themes/color.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/data/services/user_service.dart';
import 'package:flutter/material.dart';

class TambahSaldoScreen extends StatefulWidget {
  final String walletName;
  final TextEditingController controller;

  const TambahSaldoScreen({
    super.key,
    required this.walletName,
    required this.controller,
  });

  @override
  State<TambahSaldoScreen> createState() => _TambahSaldoScreenState();
}

class _TambahSaldoScreenState extends State<TambahSaldoScreen> {
  final FinancialService _financialService = FinancialService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  int? _currentUserId;
  bool _isLoading = false;
  double _currentBalance = 0.0;
  int? _accountId;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    setState(() => _isLoading = true);

    try {
      // Dapatkan semua account types
      final accountTypes = await _financialService.getAccountTypes();

      // Cari account type yang sesuai dengan wallet name
      AccountType? matchedAccountType;
      for (final accountType in accountTypes) {
        if (_normalizeWalletName(accountType.name) ==
            _normalizeWalletName(widget.walletName)) {
          matchedAccountType = accountType;
          break;
        }
      }

      if (matchedAccountType == null) {
        throw Exception('Tipe akun tidak ditemukan');
      }

      // Dapatkan user accounts dengan details
      final userId = await _userService.initializeUser();

      setState(() {
        _currentUserId = userId;
      });

      final userAccountsWithDetails =
          await _financialService.getUserAccountsWithDetails(_currentUserId!);

      // Cari user account yang sesuai dengan account type
      Map<String, dynamic>? matchedUserAccount;
      for (final accountData in userAccountsWithDetails) {
        final accountType = accountData['accountType'] as AccountType;

        if (accountType.id == matchedAccountType.id) {
          matchedUserAccount = accountData;
          break;
        }
      }

      if (matchedUserAccount != null) {
        // Akun sudah ada, ambil balance dan ID
        final userAccount = matchedUserAccount['account'] as UserAccount;
        setState(() {
          _currentBalance = userAccount.balance;
          _accountId = userAccount.id;
          _isDataLoaded = true;
        });
      } else {
        // Akun belum ada, buat baru dengan balance 0
        final newAccountId = await _financialService.createUserAccount(
          userId: _currentUserId!,
          accountTypeId: matchedAccountType.id!,
          initialBalance: 0.0,
        );

        setState(() {
          _currentBalance = 0.0;
          _accountId = newAccountId;
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading account data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data akun: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _normalizeWalletName(String name) {
    // Normalisasi nama untuk matching yang lebih fleksibel
    return name.toLowerCase().replaceAll(' ', '');
  }

  Future<void> _addSaldo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ambil nilai dari controller dan hapus format
      final amountText =
          widget.controller.text.replaceAll('.', '').replaceAll(',', '');
      final amount = double.parse(amountText);

      // Tambahkan income ke akun
      final result = await _financialService.addIncome(
        userId: _currentUserId!,
        accountId: _accountId!,
        amount: amount,
        description: 'Tambah saldo ${widget.walletName}',
        category: 'Top Up',
      );

      if (result['success']) {
        // Update balance lokal
        setState(() {
          _currentBalance = result['newBalance'];
        });

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saldo berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Bersihkan form
        widget.controller.clear();

        // Kembali ke halaman sebelumnya setelah 1 detik
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(
              context, true); // Return true untuk menandakan ada perubahan
        });
      } else {
        throw Exception(result['error'] ?? 'Gagal menambahkan saldo');
      }
    } catch (e) {
      print('Error adding saldo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan saldo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Tambah Saldo: ${widget.walletName}"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading && !_isDataLoaded
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card untuk menampilkan saldo saat ini
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Saat Ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              FinancialService.formatCurrency(_currentBalance),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Label untuk input
                    Text(
                      'Jumlah Saldo yang Ditambahkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),

                    SizedBox(height: 10),

                    // Input field untuk jumlah saldo
                    TextFormField(
                      controller: widget.controller,
                      keyboardType: TextInputType.number,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        prefixText: 'IDR ',
                        prefixStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }
                        final numericValue = value.replaceAll('.', '');
                        if (double.tryParse(numericValue) == null) {
                          return 'Masukkan jumlah yang valid';
                        }
                        if (double.parse(numericValue) <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 30),

                    // Tombol tambah saldo
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addSaldo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              )
                            : Text(
                                'Tambah Saldo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
