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

  // Stream of crops (Real-time updates for the Dashboard)
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

  // --- FINANCE COLLECTION ---

  // Record an expense or income
  Future<void> addTransaction(String userId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('finance')
          .add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to add transaction: $e");
    }
  }
}