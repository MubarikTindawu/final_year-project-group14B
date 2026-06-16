import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CROP COLLECTION ---

  // Add a new crop to the user's farm
  Future<void> addCrop(String userId, CropModel crop) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('crops')
          .add(crop.toMap());
    } catch (e) {
      throw Exception("Failed to add crop: $e");
    }
  }

  // Stream of crops (Real-time updates)
  Stream<List<CropModel>> streamCrops(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('crops')
        .orderBy('plantedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CropModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // NEW: Update crop to Harvested status
  Future<void> updateCropHarvestStatus({
    required String userId,
    required String cropId,
    required bool isHarvested,
    required String yieldAmount,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('crops')
          .doc(cropId)
          .update({
        'isHarvested': isHarvested,
        'yieldAmount': yieldAmount,
      });
    } catch (e) {
      throw Exception("Failed to update harvest status: $e");
    }
  }

  // Delete a crop
  Future<void> deleteCrop(String userId, String cropId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('crops')
          .doc(cropId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete crop: $e");
    }
  }

  // --- FINANCE COLLECTION ---

  Future<void> addTransaction(String userId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(data);
    } catch (e) {
      throw Exception("Failed to add transaction: $e");
    }
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete transaction: $e");
    }
  }
}