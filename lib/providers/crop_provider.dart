import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/crop_model.dart';
import '../services/firestore_service.dart';

class CropProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Internal list of all crops
  List<CropModel> _allCrops = [];

  // Getters: Separating Active vs History (Matched to your TabBarView)
  List<CropModel> get crops => _allCrops.where((c) => !c.isHarvested).toList();
  List<CropModel> get harvestedCrops => _allCrops.where((c) => c.isHarvested).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<CropModel>>? _cropsSubscription;

  // FETCH CROPS (Real-time Stream)
  void fetchCrops() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Only show loading indicator on the very first load
    if (_allCrops.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _cropsSubscription?.cancel();

    _cropsSubscription = _firestoreService.streamCrops(userId).listen(
          (updatedCrops) {
        _allCrops = updatedCrops;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Stream Error: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ADD NEW CROP
  Future<void> addNewCrop(CropModel crop) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.addCrop(userId, crop);
      // notifyListeners not needed here because the Stream will catch the change automatically
    } catch (e) {
      debugPrint("Add Crop Error: $e");
      rethrow;
    }
  }

  // COMPLETE HARVEST LOGIC
  Future<void> completeHarvest(String cropId, String yieldAmount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.updateCropHarvestStatus(
          userId: userId,
          cropId: cropId,
          isHarvested: true,
          yieldAmount: yieldAmount
      );
    } catch (e) {
      debugPrint("Harvest Error: $e");
      rethrow;
    }
  }

  // DELETE CROP
  Future<void> deleteCrop(String cropId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.deleteCrop(userId, cropId);
    } catch (e) {
      debugPrint("Delete Error: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _cropsSubscription?.cancel();
    super.dispose();
  }
}