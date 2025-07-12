import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fintrack_apps/data/services/service_data.dart';
import 'package:fintrack_apps/data/models/model_data.dart';
import 'package:fintrack_apps/core/themes/color.dart';

class PendapatanForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final List<Map<String, dynamic>> userAccounts;
  final int? selectedAccountId;
  final TextEditingController amountController;
  final List<String> categories;
  final String selectedCategory;
  final TextEditingController descriptionController;
  final bool isSubmitting;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final Function(int) onAccountSelected;
  final Function(String) onCategorySelected;
  final Function(String) onAmountChanged;
  final VoidCallback onSubmit;

  const PendapatanForm({
    super.key,
    required this.formKey,
    required this.selectedDate,
    required this.selectedTime,
    required this.userAccounts,
    required this.selectedAccountId,
    required this.amountController,
    required this.categories,
    required this.selectedCategory,
    required this.descriptionController,
    required this.isSubmitting,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onAccountSelected,
    required this.onCategorySelected,
    required this.onAmountChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Time Selection
            Row(
              children: [
                Expanded(
                  child: DateTimeCard(
                    title: 'Tanggal',
                    value: DateFormat('EEE, dd MMM yyyy', 'id_ID')
                        .format(selectedDate),
                    onTap: onSelectDate,
                    icon: Icons.calendar_today,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DateTimeCard(
                    title: 'Waktu',
                    value: selectedTime.format(context),
                    onTap: onSelectTime,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Account Selection
            SectionTitle(title: 'Pilih Rekening'),
            SizedBox(height: 12),

            AccountSelectionGrid(
              userAccounts: userAccounts,
              selectedAccountId: selectedAccountId,
              onAccountSelected: onAccountSelected,
            ),

            SizedBox(height: 20),

            // Amount Input
            SectionTitle(title: 'Jumlah'),
            SizedBox(height: 8),

            AmountInput(
              controller: amountController,
              onChanged: onAmountChanged,
            ),

            SizedBox(height: 20),

            // Category Selection
            SectionTitle(title: 'Kategori'),
            SizedBox(height: 8),

            CategorySelection(
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            ),

            SizedBox(height: 20),

            // Description Input
            SectionTitle(title: 'Keterangan'),
            SizedBox(height: 8),

            DescriptionInput(controller: descriptionController),

            SizedBox(height: 32),

            // Submit Button
            SubmitButton(
              isSubmitting: isSubmitting,
              onSubmit: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class DateTimeCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const DateTimeCard({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class AccountSelectionGrid extends StatelessWidget {
  final List<Map<String, dynamic>> userAccounts;
  final int? selectedAccountId;
  final Function(int) onAccountSelected;

  const AccountSelectionGrid({
    super.key,
    required this.userAccounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: userAccounts.length,
        itemBuilder: (context, index) {
          final accountMap = userAccounts[index];
          final account = accountMap['account'] as UserAccount;
          final accountType = accountMap['accountType'] as AccountType;
          final isSelected = selectedAccountId == account.id;

          return AccountCard(
            account: account,
            accountType: accountType,
            isSelected: isSelected,
            onTap: () => onAccountSelected(account.id!),
          );
        },
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final UserAccount account;
  final AccountType accountType;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.accountType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAccountIcon(accountType.name),
              size: 28,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              accountType.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              FinancialService.formatCurrency(account.balance),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String accountName) {
    switch (accountName.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'dana':
        return Icons.account_balance_wallet;
      case 'bca':
        return Icons.account_balance;
      case 'shoopepay':
        return Icons.shopping_bag;
      case 'gopay':
        return Icons.account_balance_wallet_outlined;
      case 'bri':
        return Icons.account_balance;
      case 'mandiri':
        return Icons.account_balance;
      case 'jago':
        return Icons.account_balance;
      case 'jenius':
        return Icons.account_balance;
      case 'ovo':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixText: 'IDR ',
        prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        hintText: '0',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      onChanged: onChanged,
    );
  }
}

class CategorySelection extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Wrap(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class DescriptionInput extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Masukkan keterangan pendapatan',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Keterangan tidak boleh kosong';
        }
        return null;
      },
    );
  }
}

class SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: isSubmitting
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
