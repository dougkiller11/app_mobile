import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/product_service.dart';
import 'models/cart_item.dart';
import 'pages/cart_page.dart';
import 'dart:io';

class BoissonPage extends StatelessWidget {
  const BoissonPage({super.key});

  void _addToCart(BuildContext context, Product boisson) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(
      boisson.id.toString(),
      boisson.name,
      boisson.price,
      boisson.imageUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${boisson.name} ajoutée au panier'),
        action: SnackBarAction(
          label: 'Voir le panier',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    // Si c'est une image locale (chemin fichier, pas URL)
    if (product.imageUrl.startsWith('/data/') || product.imageUrl.startsWith('/storage/')) {
      return Image.file(
        File(product.imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image locale: $err');
          return const Icon(Icons.local_drink, size: 50, color: Colors.white);
        },
      );
    }
    
    // Image par défaut pour les produits démonstration
    if (product.imageUrl.isEmpty || product.imageUrl.startsWith('assets')) {
      return Image.asset(
        'assets/images/boisson.jpg',
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => const Icon(Icons.local_drink, size: 50, color: Colors.white),
      );
    }
    
    // Image distante (URL http)
    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) => const Icon(Icons.local_drink, size: 50, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.white],
            stops: [0.0, 0.8],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Boissons'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartPage()),
                          );
                        },
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Consumer<CartProvider>(
                          builder: (ctx, cart, child) => cart.itemCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: ProductService.getProducts('boisson'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }

                    final products = snapshot.data ?? [];

                    if (products.isEmpty) {
                      return const Center(child: Text('Aucune boisson disponible'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: _buildProductImage(product),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (product.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${product.price.toStringAsFixed(2)}€',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () => _addToCart(context, product),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
