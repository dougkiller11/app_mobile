import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService {
  static SharedPreferences? _prefs;
  static const String _cartKey = 'user_cart';

  // Initialiser SharedPreferences
  static Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sauvegarder le panier
  static Future<void> saveCart(Map<String, CartItem> items) async {
    try {
      if (_prefs == null) await _initPrefs();

      // Convertir le panier en JSON
      final cartJson = json.encode(
        items.map((key, value) => MapEntry(key, value.toJson())),
      );

      // Sauvegarder dans SharedPreferences
      await _prefs?.setString(_cartKey, cartJson);
      print('Panier sauvegardé avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde du panier: $e');
    }
  }

  // Charger le panier
  static Future<Map<String, CartItem>> loadCart() async {
    try {
      if (_prefs == null) await _initPrefs();

      // Récupérer le panier depuis SharedPreferences
      final cartJson = _prefs?.getString(_cartKey);
      if (cartJson == null) return {};

      // Convertir le JSON en Map de CartItem
      final Map<String, dynamic> decoded = json.decode(cartJson);
      return decoded.map(
        (key, value) => MapEntry(key, CartItem.fromJson(value)),
      );
    } catch (e) {
      print('Erreur lors du chargement du panier: $e');
      return {};
    }
  }

  // Vider le panier
  static Future<void> clearCart() async {
    try {
      if (_prefs == null) await _initPrefs();
      await _prefs?.remove(_cartKey);
      print('Panier vidé avec succès');
    } catch (e) {
      print('Erreur lors du vidage du panier: $e');
    }
  }
} 