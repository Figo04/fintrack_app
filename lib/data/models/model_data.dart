//import 'package:fintrack_app/data/database/database_helper.dart';

class AccountType {
  final int? id;
  final String name;
  final String icon;
  final DateTime createdAt;

  AccountType({
    this.id,
    required this.name,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AccountType.fromMap(Map<String, dynamic> map) {
    return AccountType(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class UserAccount {
  final int? id;
  final int userId;
  final int accountTypeId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAccount({
    this.id,
    required this.userId,
    required this.accountTypeId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_type_id': accountTypeId,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'],
      userId: map['user_id'],
      accountTypeId: map['account_type_id'],
      balance: map['balance'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  UserAccount copyWith({
    int? id,
    int? userId,
    int? accountTypeId,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TransactionType { income, expense, transferIn, transferOut }

class Transaction {
  final int? id;
  final int userId;
  final int accountId;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.userId,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['user_id'],
      accountId: map['account_id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      amount: map['amount'].toDouble(),
      description: map['description'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
