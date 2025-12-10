import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
}

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final double amount;
  
  @HiveField(1)
  final String category;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  final String? note;

  @HiveField(4, defaultValue: TransactionType.expense)
  final TransactionType type;
  
  @HiveField(5)
  final String? id; // For Google Sheets or external DB

  Transaction({
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.type = TransactionType.expense,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name, 
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString(),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
    );
  }
}
