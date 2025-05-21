import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../services/product_service.dart';
import 'payment_page.dart'; // Importer la page de paiement
import '../services/auth_service.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  // Méthode pour afficher l'image du produit
  Widget _buildProductImage(CartItem item) {
    print('Construction de l\'image pour le produit: ${item.name}');
    print('URL de l\'image: ${item.imageUrl}');

    if (item.imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[300],
        child: const Icon(Icons.fastfood, size: 30, color: Colors.white),
      );
    }

    // Si c'est une image locale (chemin fichier)
    if (item.imageUrl.startsWith('/data/') || item.imageUrl.startsWith('/storage/')) {
      print('Tentative de chargement d\'image locale');
      return Image.file(
        File(item.imageUrl),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image locale: $err');
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.fastfood, size: 30, color: Colors.white),
          );
        },
      );
    }

    // Si c'est une image asset
    if (item.imageUrl.startsWith('assets')) {
      print('Tentative de chargement d\'image asset');
      return Image.asset(
        item.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image asset: $err');
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.fastfood, size: 30, color: Colors.white),
          );
        },
      );
    }

    // Si c'est une image réseau
    print('Tentative de chargement d\'image réseau');
    return Image.network(
      item.imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) {
        print('Erreur d\'affichage d\'image réseau: $err');
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[300],
          child: const Icon(Icons.fastfood, size: 30, color: Colors.white),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isAdmin = AuthService.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Vider le panier'),
                  content: const Text('Voulez-vous vraiment vider votre panier ?'),
                  actions: [
                    TextButton(
                      child: const Text('Non'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Oui'),
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false).clear();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade100,
              Colors.white,
            ],
          ),
        ),
        child: cart.items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Votre panier est vide',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des produits pour commencer vos achats',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final item = cart.items.values.toList()[i];
                        final productId = cart.items.keys.toList()[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: _buildProductImage(item),
                              ),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              'Total: ${(item.price * item.quantity).toStringAsFixed(2)}€',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      cart.addItem(
                                        productId,
                                        item.name,
                                        item.price,
                                        item.imageUrl,
                                      );
                                    } else {
                                      cart.removeItem(productId);
                                    }
                                  },
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    cart.addItem(
                                      productId,
                                      item.name,
                                      item.price,
                                      item.imageUrl,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(15),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                '${cart.totalAmount.toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentPage(
                                      totalAmount: cart.totalAmount,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Procéder au paiement',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 