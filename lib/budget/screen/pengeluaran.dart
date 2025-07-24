import 'package:fintrack_apps/core/themes/color.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/budget/widgets/pengeluaran_widget.dart';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key, required this.userId});

  final int userId;

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  final FinancialService _financialService = FinancialService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedAccountId;
  String _selectedCategory = 'Jajan';

  // Acount data
  List<Map<String, dynamic>> _userAccounts = [];
  List<AccountType> _accountTypes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Categories
  final List<String> _categories = [
    'Jajan',
    'Makanan',
    'Minuman',
    'Makanan dan minuman',
    'Listrik',
    'Belanja',
    'Bensin',
    'Top Up',
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadAccountData();
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    try {
      final AccountTypes = await _financialService.getAccountTypes();
      final UserAccounts =
          await _financialService.getUserAccountsWithDetails(widget.userId);

      setState(() {
        _accountTypes = AccountTypes;
        _userAccounts = UserAccounts;
        _isLoading = false;
      });

      if (_userAccounts.isEmpty) {
        await _createDefaultAccouts();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal Memuat data akun: $e');
    }
  }

  Future<void> _loadTransactionHistory() async {
    try {
      final transactions =
          await _financialService.getTransactionHistory(widget.userId);

      final expenseTransactions =
          transactions.where((t) => t.type == 'expense').toList();

      print('=== DEBUG TRANSACTION HISTORY ===');
      print('Total transactions: ${transactions.length}');
      print('Expense transactions: ${expenseTransactions.length}');

      for (int i = 0; i < transactions.length && i < 5; i++) {
        print(
          'Transaction $i: type=${transactions[i].type}, amount=${transactions[i].amount}, desc=${transactions[i].description}',
        );
      }
    } catch (e) {
      print('Error loading transaction history: $e');
    }
  }

  Future<void> _createDefaultAccouts() async {
    try {
      for (final accountType in _accountTypes) {
        await _financialService.createUserAccount(
          userId: widget.userId,
          accountTypeId: accountType.id!,
          initialBalance: 0.0,
        );
      }

      final userAccounts =
          await _financialService.getUserAccountsWithDetails(widget.userId);
      setState(() {
        _userAccounts = userAccounts;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal Memuat akun default: $e');
    }
  }

  // Date & time Selection Methods
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Form Submission Methods
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null) {
      _showErrorSnackBar('Silahkan pilih rekening');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));

      final SelectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      print('=== DEBUG SUBMIT TRANSACTION ===');
      print('Amount: $amount');
      print('Description: ${_descriptionController.text.trim()}');
      print('Category: $_selectedCategory');
      print('Account ID: $_selectedAccountId');
      print('DateTime: $SelectedDateTime');

      final result = await _financialService.addExpense(
        userId: widget.userId,
        accountId: _selectedAccountId!,
        amount: amount,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      print('=== DEBUG SUBMIT RESULT ===');
      print('Result: $result');

      if (result['success']) {
        _showSuccessSnackBar('Pendapatan berhasil ditambahkan!\n'
            'Saldo baru: ${FinancialService.formatCurrency(result['newBalance'])}\n'
            'Total saldo: ${FinancialService.formatCurrency(result['totalBalance'])}');

        _clearForm();
        await _loadTransactionHistory();
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Gagal menambahkan pengeluaran: ${result['erorr']}');
      }
    } catch (e) {
      print('Error submitting transaction: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedAccountId = null;
      _selectedCategory = 'Jajan';
    });
  }

  //utilty Methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.fivety,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.third,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return value;

    final number = value.replaceAll('.', '');
    if (number.isEmpty) return '';

    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(int.parse(number)).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tambah Pengeluaran',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : PengeluaranForm(
              formKey: _formKey,
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              userAccounts: _userAccounts,
              selectedAccountId: _selectedAccountId,
              amountController: _amountController,
              categories: _categories,
              selectedCategory: _selectedCategory,
              descriptionController: _descriptionController,
              isSubmitting: _isSubmitting,
              onSelectDate: _selectDate,
              onSelectTime: _selectTime,
              onAccountSelected: (accountId) {
                setState(() {
                  _selectedAccountId = accountId;
                });
              },
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onAmountChanged: (value) {
                final formatted = _formatCurrency(value.replaceAll('.', ''));
                if (formatted != value) {
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection:
                        TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
              onSubmit: _submitTransaction,
            ),
    );
  }
}
