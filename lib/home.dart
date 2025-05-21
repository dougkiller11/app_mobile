import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'models/cart_item.dart';
import 'pages/cart_page.dart';
// Importer les pages
import 'burger.dart';
import 'pizza.dart';
import 'boisson.dart';
import 'entree.dart';
import 'dessert.dart';
import 'sushi.dart';
import 'admin_home.dart';
import 'pages/settings_page.dart';  // Import de notre page profil
import 'screens/reservation_screen.dart'; // <-- AJOUT DE L'IMPORT

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(BuildContext context, int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1: // Panier
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
        break;
      case 2: // Profil (ancien Réglages)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileMenuPage()),
        );
        break;
    }
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
              // En-tête avec logo et titre
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Mon Restaurant',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart, color: Colors.white),
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
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await AuthService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // BOUTON DE RESERVATION <-- AJOUT DU BOUTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Réserver une Table'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReservationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Change color as you like
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50), // Make it wide
                    textStyle: const TextStyle(fontSize: 18)
                  ),
                ),
              ),

              // Contenu principal avec la grille
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        context,
                        'Burger',
                        'assets/images/burger.jpg',
                        '/burger',
                      ),
                      _buildMenuCard(
                        context,
                        'Pizza',
                        'assets/images/pizza.jpg',
                        '/pizza',
                      ),
                      _buildMenuCard(
                        context,
                        'Boissons',
                        'assets/images/boisson.jpg',
                        '/boisson',
                      ),
                      _buildMenuCard(
                        context,
                        'Desserts',
                        'assets/images/dessert.jpg',
                        '/dessert',
                      ),
                      _buildMenuCard(
                        context,
                        'Sushi',
                        'assets/images/sushi.jpeg',
                        '/sushi',
                      ),
                      _buildMenuCard(
                        context,
                        'Entrées',
                        'assets/images/entree.jpg',
                        '/entree',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => _onItemTapped(context, index),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Consumer<CartProvider>(
                      builder: (ctx, cart, child) => cart.itemCount > 0
                          ? Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ],
              ),
              label: 'Panier',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String imagePath,
    String route,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Widget page;
          switch (title.toLowerCase()) {
            case 'burger':
              page = const BurgerPage();
              break;
            case 'pizza':
              page = const PizzaPage();
              break;
            case 'boissons':
              page = const BoissonPage();
              break;
            case 'desserts':
              page = const DessertPage();
              break;
            case 'sushi':
              page = const SushiPage();
              break;
            case 'entrées':
              page = const EntreePage();
              break;
            default:
              return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image $imagePath: $error');
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.restaurant,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
