import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class TestClientPage extends StatefulWidget {
  const TestClientPage({super.key});

  @override
  State<TestClientPage> createState() => _TestClientPageState();
}

class _TestClientPageState extends State<TestClientPage> {
  String? _userEmail;
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeMenu();
  }
  
  Future<void> _loadUserInfo() async {
    final email = AuthService.getCurrentUserEmail();
    setState(() {
      _userEmail = email;
    });
  }
  
  void _initializeMenu() {
    // Menu de démonstration
    setState(() {
      _menuItems = [
        {
          'id': '1',
          'name': 'Burger Classic',
          'description': 'Un délicieux burger avec steak, salade, tomate, oignon',
          'price': 8.99,
          'category': 'burger',
          'imageUrl': 'https://via.placeholder.com/150',
        },
        {
          'id': '2',
          'name': 'Pizza Margherita',
          'description': 'Pizza avec sauce tomate, mozzarella et basilic',
          'price': 10.99,
          'category': 'pizza',
          'imageUrl': 'https://via.placeholder.com/150',
        },
        {
          'id': '3',
          'name': 'Sushi Salmon',
          'description': 'Sushi au saumon frais',
          'price': 12.99,
          'category': 'sushi',
          'imageUrl': 'https://via.placeholder.com/150',
        },
        {
          'id': '4',
          'name': 'Tiramisu',
          'description': 'Dessert italien au café et mascarpone',
          'price': 6.99,
          'category': 'dessert',
          'imageUrl': 'https://via.placeholder.com/150',
        },
        {
          'id': '5',
          'name': 'Coca-Cola',
          'description': 'Boisson gazeuse rafraîchissante',
          'price': 2.99,
          'category': 'boisson',
          'imageUrl': 'https://via.placeholder.com/150',
        },
      ];
    });
  }
  
  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere((cartItem) => cartItem['id'] == item['id']);
      
      if (existingItemIndex >= 0) {
        _cartItems[existingItemIndex]['quantity']++;
      } else {
        final newItem = {...item, 'quantity': 1};
        _cartItems.add(newItem);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} ajouté au panier'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _removeFromCart(String id) {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == id);
    });
  }
  
  double get _totalPrice {
    return _cartItems.fold(0, (total, item) => total + (item['price'] * item['quantity']));
  }
  
  void _placeOrder() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Simuler la commande
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande envoyée avec succès!'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _cartItems.clear();
    });
  }
  
  void _logout() async {
    await AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Restaurant'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildCartSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: Colors.orange),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenue,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _userEmail ?? 'Client',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Text(
                            'Notre Menu',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final item = _menuItems[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    item['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['description']),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${item['price'].toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                                    onPressed: () => _addToCart(item),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildCartSheet(),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.shopping_cart),
        label: Text('${_cartItems.length} articles'),
      ),
    );
  }
  
  Widget _buildCartSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Votre Panier',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _cartItems.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Votre panier est vide'),
                )
              : Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('${item['quantity']} x ${item['price'].toStringAsFixed(2)} €'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromCart(item['id']),
                        ),
                      );
                    },
                  ),
                ),
          if (_cartItems.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Commander'),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 