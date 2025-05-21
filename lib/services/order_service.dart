import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  // Convertir CartItem en OrderItem
  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      productId: cartItem.name, // Utiliser le nom comme ID de produit
      name: cartItem.name,
      quantity: cartItem.quantity,
      price: cartItem.price,
      imageUrl: cartItem.imageUrl,
    );
  }
}

class Order {
  final String id;
  final String userEmail;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? deliveryAddress;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.userEmail,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userEmail: json['userEmail'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'En préparation',
      deliveryAddress: json['deliveryAddress'],
      paymentMethod: json['paymentMethod'],
    );
  }
}

class OrderService {
  static const String _ordersKey = 'user_orders';

  // Sauvegarder une commande
  static Future<bool> saveOrder(Order order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer les commandes existantes
      List<Order> existingOrders = await getOrdersByEmail(order.userEmail);
      
      // Ajouter la nouvelle commande
      existingOrders.add(order);
      
      // Convertir la liste complète en JSON
      final List<Map<String, dynamic>> ordersJson = 
          existingOrders.map((order) => order.toJson()).toList();
      
      // Sauvegarder la liste mise à jour
      return await prefs.setString(
        '${_ordersKey}_${order.userEmail}', 
        jsonEncode(ordersJson)
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde de la commande: $e');
      return false;
    }
  }

  // Récupérer toutes les commandes d'un utilisateur
  static Future<List<Order>> getOrdersByEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('${_ordersKey}_$email');
      
      if (ordersJson != null) {
        final List<dynamic> decodedList = jsonDecode(ordersJson);
        return decodedList
            .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des commandes: $e');
      return [];
    }
  }

  // Mettre à jour le statut d'une commande
  static Future<bool> updateOrderStatus(String email, String orderId, String newStatus) async {
    try {
      List<Order> orders = await getOrdersByEmail(email);
      
      // Trouver et mettre à jour la commande
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        // Créer une nouvelle commande mise à jour (car Order est immutable)
        Order updatedOrder = Order(
          id: orders[index].id,
          userEmail: orders[index].userEmail,
          date: orders[index].date,
          items: orders[index].items,
          total: orders[index].total,
          status: newStatus,
          deliveryAddress: orders[index].deliveryAddress,
          paymentMethod: orders[index].paymentMethod,
        );
        
        // Remplacer l'ancienne commande par la nouvelle
        orders[index] = updatedOrder;
        
        // Convertir en JSON et sauvegarder
        final prefs = await SharedPreferences.getInstance();
        final ordersJson = jsonEncode(orders.map((o) => o.toJson()).toList());
        return await prefs.setString('${_ordersKey}_$email', ordersJson);
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de la commande: $e');
      return false;
    }
  }
  
  // Générer un ID de commande unique format 'ORD-XXX'
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = timestamp % 1000;
    return 'ORD-${randomSuffix.toString().padLeft(3, '0')}';
  }
} 