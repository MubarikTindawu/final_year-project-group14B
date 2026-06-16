import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_model.dart';

class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<InventoryModel> _inventoryItems = [];
  bool _isLoading = false;

  List<InventoryModel> get inventoryItems => _inventoryItems;
  bool get isLoading => _isLoading;

  // Calculates how many items are currently at or below the threshold
  int get lowStockCount => _inventoryItems
      .where((item) => item.quantity <= item.minThreshold)
      .length;

  // FETCH: Gets all inventory items for the logged-in user
  Future<void> fetchInventory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      _inventoryItems = snapshot.docs
          .map((doc) => InventoryModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Inventory Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE: Handles both Restocking (+) and Selling/Using (-)
  Future<void> updateStockLevel(String itemId, double amount, {bool isRestock = true}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _db.collection('users').doc(user.uid).collection('inventory').doc(itemId);

      final doc = await docRef.get();
      if (!doc.exists) return;

      double currentQty = (doc.data()?['quantity'] ?? 0.0).toDouble();
      double newQty = isRestock ? (currentQty + amount) : (currentQty - amount);

      // Prevent negative stock levels
      if (newQty < 0) newQty = 0;

      await docRef.update({'quantity': newQty});

      // Update the local list so the UI changes instantly
      int index = _inventoryItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _inventoryItems[index].quantity = newQty;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update Stock Error: $e");
    }
  }

  // ADD: Creates a new item OR updates quantity if name matches
  Future<bool> addInventoryItem(InventoryModel item) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check for existing item with the same name (case-insensitive)
      final existingIndex = _inventoryItems.indexWhere(
              (i) => i.itemName.toLowerCase() == item.itemName.toLowerCase()
      );

      if (existingIndex != -1) {
        // ITEM EXISTS: Use the existing ID to update the stock level
        final existingItem = _inventoryItems[existingIndex];
        await updateStockLevel(existingItem.id, item.quantity, isRestock: true);
        return true;
      }

      // ITEM IS NEW: Add fresh document to Firestore
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .add(item.toMap());

      // Refresh the list to include the new item and its Firebase ID
      await fetchInventory();
      return true;
    } catch (e) {
      debugPrint("Add Inventory Error: $e");
      return false;
    }
  }

  // DELETE: Removes an item permanently
  Future<void> deleteInventoryItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(itemId)
          .delete();

      _inventoryItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      debugPrint("Delete Inventory Error: $e");
    }
  }
}