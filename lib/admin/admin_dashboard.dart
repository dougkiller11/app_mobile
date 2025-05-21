import 'package:flutter/material.dart';
import 'admin_product_page.dart';
import '../screens/user_management_screen.dart';
import 'admin_profile_page.dart';
import 'manage_reservations_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserManagementScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrateur'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
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
        child: Column(
          children: [
            // En-tête avec titre
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Gestion du Restaurant',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Grille des catégories
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCategoryCard(
                    context,
                    'Burgers',
                    'assets/images/burger.jpg',
                    Icons.lunch_dining,
                    'burger',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Pizzas',
                    'assets/images/pizza.jpg',
                    Icons.local_pizza,
                    'pizza',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Boissons',
                    'assets/images/boisson.jpg',
                    Icons.local_drink,
                    'boisson',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Sushis',
                    'assets/images/sushi.jpeg',
                    Icons.set_meal,
                    'sushi',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Entrées',
                    'assets/images/entree.jpg',
                    Icons.restaurant,
                    'entree',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Desserts',
                    'assets/images/dessert.jpg',
                    Icons.cake,
                    'dessert',
                    navigateToProductPage: true,
                  ),
                  _buildCategoryCard(
                    context,
                    'Réservations',
                    'assets/images/reservation_icon.png',
                    Icons.event_note,
                    'reservations',
                    navigateToProductPage: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, 
      IconData fallbackIcon, String type, {bool navigateToProductPage = true}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          if (navigateToProductPage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProductPage(
                  title: 'Gestion des $title',
                  category: type,
                ),
              ),
            );
          } else if (type == 'reservations') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageReservationsScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 80,
              width: 80,
              errorBuilder: (context, error, stackTrace) => Icon(
                fallbackIcon,
                size: 80,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 