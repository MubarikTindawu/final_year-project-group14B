import 'package:cloud_firestore/cloud_firestore.dart';

class CropModel {
  final String id;
  final String name;
  final String variety;
  final double area;
  final DateTime plantedDate;
  final DateTime expectedHarvestDate;
  final double growthProgress;
  final bool isHarvested;
  final String yieldAmount;

  CropModel({
    required this.id,
    required this.name,
    required this.variety,
    required this.area,
    required this.plantedDate,
    required this.expectedHarvestDate,
    required this.growthProgress,
    this.isHarvested = false,
    this.yieldAmount = '',
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'variety': variety,
      'area': area,
      'plantedDate': Timestamp.fromDate(plantedDate),
      'expectedHarvestDate': Timestamp.fromDate(expectedHarvestDate),
      'growthProgress': growthProgress,
      'isHarvested': isHarvested,
      'yieldAmount': yieldAmount,
    };
  }

  // UPDATED: Factory with "Safe Date" parsing
  factory CropModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Helper function to handle both Timestamp and DateTime (Offline safety)
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is DateTime) return date;
      return DateTime.now(); // Fallback
    }

    return CropModel(
      id: documentId,
      name: map['name'] ?? '',
      variety: map['variety'] ?? '',
      area: (map['area'] ?? 0.0).toDouble(),
      plantedDate: parseDate(map['plantedDate']),
      expectedHarvestDate: parseDate(map['expectedHarvestDate']),
      growthProgress: (map['growthProgress'] ?? 0.0).toDouble(),
      isHarvested: map['isHarvested'] ?? false,
      yieldAmount: map['yieldAmount'] ?? '',
    );
  }

  // --- LOGIC HELPERS ---

  int get totalDays {
    int days = expectedHarvestDate.difference(plantedDate).inDays;
    return days > 0 ? days : 1; // Prevent division by zero
  }

  int get daysRemaining {
    if (isHarvested) return 0;
    // We normalize to midnight to avoid "0 days" showing up too early
    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    final harvestClean = DateTime(expectedHarvestDate.year, expectedHarvestDate.month, expectedHarvestDate.day);

    final difference = harvestClean.difference(todayClean).inDays;
    return difference > 0 ? difference : 0;
  }

  double get calculatedProgress {
    if (isHarvested) return 1.0;

    final daysPassed = DateTime.now().difference(plantedDate).inDays;
    return (daysPassed / totalDays).clamp(0.0, 1.0);
  }

  String get growthStage {
    if (isHarvested) return "Harvested";

    final progress = calculatedProgress;
    if (progress < 0.2) return "Seedling";
    if (progress < 0.5) return "Vegetative";
    if (progress < 0.8) return "Flowering";
    if (progress < 1.0) return "Maturing";
    return "Harvest Ready";
  }
}