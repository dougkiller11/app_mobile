import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class CartItem {
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }

  CartItem copyWith({
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartProvider extends ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Charger le panier au démarrage
  Future<void> loadCart() async {
    _items = await CartService.loadCart();
    notifyListeners();
  }

  // Ajouter un produit au panier
  Future<void> addItem(String productId, String name, double price, String imageUrl) async {
    if (_items.containsKey(productId)) {
      // Mettre à jour la quantité
      _items.update(
        productId,
        (existingItem) => CartItem(
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          imageUrl: existingItem.imageUrl,
        ),
      );
    } else {
      // Ajouter un nouveau produit
      _items.putIfAbsent(
        productId,
        () => CartItem(
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
        ),
      );
    }
    // Sauvegarder le panier
    await CartService.saveCart(_items);
    notifyListeners();
  }

  // Supprimer un produit du panier
  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    // Sauvegarder le panier
    await CartService.saveCart(_items);
    notifyListeners();
  }

  // Vider le panier
  Future<void> clear() async {
    _items = {};
    // Sauvegarder le panier vide
    await CartService.clearCart();
    notifyListeners();
  }
} 