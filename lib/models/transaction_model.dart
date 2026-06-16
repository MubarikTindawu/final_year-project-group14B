class TransactionModel {
  final String id;
  final String category;    // e.g., 'Crop Sale' for income or 'Fertilizer' for expense
  final double amount;
  final DateTime date;
  final String note;
  final bool isIncome;      // FIXED: true = Income, false = Expense

  TransactionModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.isIncome = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'isIncome': isIncome,
    };
  }

  // Create from Firestore Document
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      category: map['category'] ?? 'General',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      note: map['note'] ?? '',
      isIncome: map['isIncome'] ?? false,
    );
  }
}