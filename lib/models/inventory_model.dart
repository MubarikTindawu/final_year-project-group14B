class InventoryModel {
  final String id;
  final String itemName;

  // Non-final to allow local state updates in the Provider
  double quantity;

  final String unit;
  final double minThreshold;
  final String category;

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.minThreshold = 5.0,
    this.category = 'General',
  });

  // Convert Model to Map for Firestore
  // Note: We don't include 'id' here because Firestore uses the Doc ID as the unique key
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'minThreshold': minThreshold,
      'category': category,
    };
  }

  // Create Model from Firestore Document
  factory InventoryModel.fromMap(String id, Map<String, dynamic> map) {
    return InventoryModel(
      id: id,
      itemName: map['itemName'] ?? 'Unknown Item',

      // Using 'as num' and 'toDouble()' is the safest way to handle
      // Firestore numbers which can fluctuate between int and double.
      quantity: (map['quantity'] as num? ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'Units',
      minThreshold: (map['minThreshold'] as num? ?? 5.0).toDouble(),
      category: map['category'] ?? 'General',
    );
  }

  // HELPER: Quick check if stock is low
  bool get isLowStock => quantity <= minThreshold;
}