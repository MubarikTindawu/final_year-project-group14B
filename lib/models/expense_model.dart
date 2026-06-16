class TransactionModel {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final bool isIncome; // true for Income, false for Expense

  TransactionModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'isIncome': isIncome,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      category: map['category'] ?? 'General',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      isIncome: map['isIncome'] ?? false,
    );
  }
}