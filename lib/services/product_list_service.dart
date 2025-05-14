import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class ProductListService {
  static final ProductListService _instance = ProductListService._internal();
  factory ProductListService() => _instance;

  static const String _prefsKey = 'productList';

  ProductListService._internal() {
    _initializationDone = _loadProductsFromPrefs();
  }

  late final Future<void> _initializationDone;

  List<String> _products = [];

  final ValueNotifier<List<String>> _productsNotifier = ValueNotifier([]);

  ValueNotifier<List<String>> get productsNotifier {
    return _productsNotifier;
  }

  Future<List<String>> get products async {
    await _initializationDone; 
    return List.unmodifiable(_products); 
  }


  Future<void> addProduct(String product) async {
    await _initializationDone;
    if (product.trim().isNotEmpty && !_products.contains(product.trim())) {
      _products.add(product.trim());
      await _updateAndSave();
    }
  }

  Future<void> addProducts(List<String> productsToAdd) async {
    await _initializationDone;
    bool changed = false;
    for (var product in productsToAdd) {
      if (product.trim().isNotEmpty && !_products.contains(product.trim())) {
        _products.add(product.trim());
        changed = true;
      }
    }
    if (changed) {
      await _updateAndSave();
    }
  }

  Future<void> removeProduct(int index) async {
    await _initializationDone;
    if (index >= 0 && index < _products.length) {
      _products.removeAt(index);
      await _updateAndSave();
    }
  }

  Future<void> editProduct(int index, String updatedProduct) async {
    await _initializationDone;
    if (index >= 0 && index < _products.length && updatedProduct.trim().isNotEmpty) {
      _products[index] = updatedProduct.trim();
      await _updateAndSave();
    }
  }


  Future<void> _loadProductsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_prefsKey);
      if (savedList != null) {
        _products = savedList;
        _productsNotifier.value = List.from(_products);
        print("[ProductListService] Loaded ${_products.length} products from SharedPreferences.");
      } else {
         print("[ProductListService] No products found in SharedPreferences.");
         _productsNotifier.value = [];
      }
    } catch (e) {
      print("Error loading products from SharedPreferences: $e");
      _products = [];
      _productsNotifier.value = [];
    }
  }

  Future<void> _updateAndSave() async {
    _productsNotifier.value = List.from(_products);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _products);
      print("[ProductListService] Saved ${_products.length} products to SharedPreferences.");
    } catch (e) {
      print("Error saving products to SharedPreferences: $e");
    }
  }
} 