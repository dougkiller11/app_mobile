import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['image_url'] ?? '';
    print('Image URL from JSON: $imageUrl'); // Log pour déboguer

    // Si l'URL est vide ou commence par 'assets', utiliser l'image par défaut
    if (imageUrl.isEmpty || imageUrl.startsWith('assets')) {
      final category = json['category'] ?? '';
      imageUrl = 'assets/images/${category}.jpg';
      print('Using default image: $imageUrl'); // Log pour déboguer
    }

    return Product(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: imageUrl,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'category': category,
    };
  }
}

class ProductService {
  // Liste statique pour simuler une base de données en mémoire
  static final Map<String, List<Product>> _localProducts = {};
  static SharedPreferences? _prefs;
  
  // Initialiser SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProductsFromStorage();
  }
  
  // Charger les produits depuis le stockage local
  static Future<void> _loadProductsFromStorage() async {
    try {
      if (_prefs == null) {
        await init();
      }
      
      // Charger les produits par catégorie
      final categories = ['burger', 'pizza', 'boisson', 'entree', 'dessert', 'sushi'];
      
      for (final category in categories) {
        final productsJson = _prefs?.getString('products_$category');
        if (productsJson != null) {
          final List<dynamic> productsData = json.decode(productsJson);
          _localProducts[category] = productsData
              .map((data) => Product.fromJson(data))
              .toList();
          
          print('Chargé ${_localProducts[category]!.length} produits pour la catégorie $category');
          // Log des URLs d'images pour chaque produit
          for (final product in _localProducts[category]!) {
            print('Produit ${product.name}: imageUrl = ${product.imageUrl}');
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
    }
  }
  
  // Sauvegarder les produits dans le stockage local
  static Future<void> _saveProductsToStorage(String category) async {
    try {
      if (_prefs == null) {
        await init();
      }
      
      if (_localProducts.containsKey(category)) {
        final productsJson = json.encode(
          _localProducts[category]!.map((product) => product.toJson()).toList()
        );
        await _prefs?.setString('products_$category', productsJson);
        print('Sauvegardé ${_localProducts[category]!.length} produits pour la catégorie $category');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde des produits: $e');
    }
  }

  static Future<List<Product>> getProducts(String category) async {
    try {
      // Retourner les produits locaux en mémoire s'ils existent
      if (_localProducts.containsKey(category)) {
        print('Retour des produits locaux pour la catégorie $category: ${_localProducts[category]!.length} produits');
        return _localProducts[category]!;
      }
      
      // Mode test/démo activé
      print('Mode démo: Retour de produits fictifs pour la catégorie $category');
      
      // Produits fictifs selon la catégorie
      List<Product> demoProducts = [];
      
      if (category == 'burger') {
        demoProducts.add(Product(
          id: 'demo1',
          name: 'Burger Classic',
          price: 9.99,
          description: 'Un délicieux burger avec steak, fromage, salade et tomate',
          imageUrl: 'assets/images/burger.jpg',
          category: 'burger',
        ));
        demoProducts.add(Product(
          id: 'demo2',
          name: 'Burger Cheese',
          price: 11.99,
          description: 'Double fromage, steak haché et sauce spéciale',
          imageUrl: 'assets/images/burger.jpg',
          category: 'burger',
        ));
      } else if (category == 'pizza') {
        demoProducts.add(Product(
          id: 'demo3',
          name: 'Pizza Margherita',
          price: 10.99,
          description: 'Tomate, mozzarella et basilic frais',
          imageUrl: 'assets/images/pizza.jpg',
          category: 'pizza',
        ));
        demoProducts.add(Product(
          id: 'demo4',
          name: 'Pizza Reine',
          price: 12.99,
          description: 'Tomate, mozzarella, jambon et champignons',
          imageUrl: 'assets/images/pizza.jpg',
          category: 'pizza',
        ));
        demoProducts.add(Product(
          id: 'demo5',
          name: 'Pizza 4 Fromages',
          price: 13.99,
          description: 'Tomate, mozzarella, gorgonzola, parmesan et chèvre',
          imageUrl: 'assets/images/pizza.jpg',
          category: 'pizza',
        ));
      } else if (category == 'boisson') {
        demoProducts.add(Product(
          id: 'demo6',
          name: 'Coca-Cola',
          price: 3.50,
          description: 'Boisson fraîche 33cl',
          imageUrl: 'assets/images/boisson.jpg',
          category: 'boisson',
        ));
      } else if (category == 'dessert') {
        demoProducts.add(Product(
          id: 'demo7',
          name: 'Tiramisu',
          price: 6.50,
          description: 'Dessert italien au café et mascarpone',
          imageUrl: 'assets/images/dessert.jpg',
          category: 'dessert',
        ));
      } else if (category == 'entree') {
        demoProducts.add(Product(
          id: 'demo8',
          name: 'Salade César',
          price: 8.50,
          description: 'Laitue, poulet grillé, parmesan et croûtons',
          imageUrl: 'assets/images/entree.jpg',
          category: 'entree',
        ));
      } else if (category == 'sushi') {
        demoProducts.add(Product(
          id: 'demo9',
          name: 'California Roll',
          price: 9.50,
          description: 'Rouleau de riz avec crabe, avocat et concombre',
          imageUrl: 'assets/images/sushi.jpeg',
          category: 'sushi',
        ));
      }
      
      // Sauvegarder les produits de démo dans le stockage local
      _localProducts[category] = demoProducts;
      await _saveProductsToStorage(category);
      
      // Log des URLs d'images pour chaque produit de démo
      for (final product in demoProducts) {
        print('Produit démo ${product.name}: imageUrl = ${product.imageUrl}');
      }
      
      return demoProducts;
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  static Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      // Ajouter le produit à la liste locale temporaire
      final category = productData['category'].toString();
      final name = productData['name'].toString();
      final description = productData['description'].toString();
      final price = double.tryParse(productData['price'].toString()) ?? 0.0;
      final imagePath = productData['image'] as String;
      
      print('Ajout d\'un nouveau produit:');
      print('Catégorie: $category');
      print('Nom: $name');
      print('Image: $imagePath');
      
      // Créer un nouveau produit local
      final newProduct = Product(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        price: price,
        imageUrl: imagePath,
        category: category,
      );
      
      // Ajouter à la liste locale
      if (!_localProducts.containsKey(category)) {
        _localProducts[category] = [];
      }
      
      _localProducts[category]!.add(newProduct);
      print('Produit ajouté localement: ${newProduct.name}');
      print('Nombre de produits dans la catégorie $category: ${_localProducts[category]!.length}');
      
      // Sauvegarder les produits dans le stockage local
      await _saveProductsToStorage(category);
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout du produit: $e');
      return false;
    }
  }

  static Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      // Mise à jour d'un produit local
      if (id.startsWith('local-')) {
        // Extraire les données
        final category = productData['category'].toString();
        final name = productData['name'].toString();
        final description = productData['description'].toString();
        final price = double.tryParse(productData['price'].toString()) ?? 0.0;
        final imagePath = productData['image'] as String;
        
        print('Mise à jour d\'un produit:');
        print('ID: $id');
        print('Catégorie: $category');
        print('Nom: $name');
        print('Image: $imagePath');
        
        // Parcourir toutes les catégories pour trouver le produit
        for (final cat in _localProducts.keys) {
          final index = _localProducts[cat]!.indexWhere((p) => p.id == id);
          if (index >= 0) {
            // Si la catégorie a changé
            if (cat != category) {
              // Supprimer de l'ancienne catégorie
              final productToMove = _localProducts[cat]![index];
              _localProducts[cat]!.removeAt(index);
              
              // Ajouter à la nouvelle catégorie
              if (!_localProducts.containsKey(category)) {
                _localProducts[category] = [];
              }
              
              // Créer produit mis à jour
              final updatedProduct = Product(
                id: id,
                name: name,
                description: description,
                price: price,
                imageUrl: imagePath,
                category: category,
              );
              
              _localProducts[category]!.add(updatedProduct);
            } else {
              // Mise à jour dans la même catégorie
              _localProducts[cat]![index] = Product(
                id: id,
                name: name,
                description: description,
                price: price,
                imageUrl: imagePath,
                category: category,
              );
            }
            
            print('Produit mis à jour localement: $id');
            
            // Sauvegarder les produits dans le stockage local
            await _saveProductsToStorage(category);
            
            return true;
          }
        }
        return false; // Produit non trouvé
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du produit: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      print('Tentative de suppression du produit avec l\'ID: $id');
      
      // Parcourir toutes les catégories pour trouver le produit
      for (final category in _localProducts.keys) {
        final index = _localProducts[category]!.indexWhere((p) => p.id == id);
        if (index >= 0) {
          print('Produit trouvé dans la catégorie: $category');
          
          // Supprimer le produit de la liste
          _localProducts[category]!.removeAt(index);
          print('Produit supprimé de la liste locale');
          
          // Sauvegarder les produits dans le stockage local
          await _saveProductsToStorage(category);
          print('Produits sauvegardés dans le stockage local');
          
          return true;
        }
      }
      
      print('Produit non trouvé avec l\'ID: $id');
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du produit: $e');
      return false;
    }
  }
} 