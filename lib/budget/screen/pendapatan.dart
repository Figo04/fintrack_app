import 'package:fintrack_apps/budget/widgets/pendapatan_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/core/themes/color.dart';

class PendapatanScreen extends StatefulWidget {
  final int userId;

  const PendapatanScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PendapatanScreen> createState() => _PendapatanScreenState();
}

class _PendapatanScreenState extends State<PendapatanScreen> {
  final FinancialService _financialService = FinancialService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedAccountId;
  String _selectedCategory = 'Gaji Bulanan';

  // Account data
  List<Map<String, dynamic>> _userAccounts = [];
  List<AccountType> _accountTypes = [];
  //List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Categories
  final List<String> _categories = [
    'Gaji Bulanan',
    'Freelance',
    'Bonus',
    'Investasi',
    'Bisnis',
    'Hadiah',
    'Lainnya'
  ];

  @override
  void initState() {
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

  // Data Loading Methods
  Future<void> _loadAccountData() async {
    try {
      final accountTypes = await _financialService.getAccountTypes();
      final userAccounts =
          await _financialService.getUserAccountsWithDetails(widget.userId);

      setState(() {
        _accountTypes = accountTypes;
        _userAccounts = userAccounts;
        _isLoading = false;
      });

      if (_userAccounts.isEmpty) {
        await _createDefaultAccounts();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data akun: $e');
    }
  }

  Future<void> _loadTransactionHistory() async {
    try {
      final transactions =
          await _financialService.getTransactionHistory(widget.userId);

      final incomeTransactions =
          transactions.where((t) => t.type == 'income').toList();

      print('=== DEBUG TRANSACTION HISTORY ===');
      print('Total transactions: ${transactions.length}');
      print('Income transactions: ${incomeTransactions.length}');

      for (int i = 0; i < transactions.length && i < 5; i++) {
        print(
            'Transaction $i: type=${transactions[i].type}, amount=${transactions[i].amount}, desc=${transactions[i].description}');
      }
    } catch (e) {
      print('Error loading transaction history: $e');
    }
  }

  Future<void> _createDefaultAccounts() async {
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
      _showErrorSnackBar('Gagal membuat akun default: $e');
    }
  }

  // Date & Time Selection Methods
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
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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
      _showErrorSnackBar('Silakan pilih rekening');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));

      final selectedDateTime = DateTime(
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
      print('DateTime: $selectedDateTime');

      final result = await _financialService.addIncome(
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
        _showErrorSnackBar('Gagal menambahkan pendapatan: ${result['error']}');
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
      _selectedCategory = 'Gaji Bulanan';
    });
  }

  // Utility Methods
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
          'Tambah Pendapatan',
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
          : PendapatanForm(
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
