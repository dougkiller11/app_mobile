import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'models/cart_item.dart';  // Contient à la fois CartItem et CartProvider
import 'inscription.dart';
import 'burger.dart';
import 'pizza.dart';
import 'boisson.dart';
import 'dessert.dart';
import 'sushi.dart';
import 'entree.dart';
import 'forgot_password.dart';
import 'login_page.dart';
import 'admin_home.dart';
import 'admin/burger_admin.dart';
import 'admin/pizza_admin.dart';
import 'admin/boisson_admin.dart';
import 'admin/dessert_admin.dart';
import 'admin/sushi_admin.dart';
import 'admin/entree_admin.dart';
import 'home.dart';  // Importer la vraie page d'accueil client
import 'admin/admin_product_page.dart'; // Ajout de l'import pour admin_product_page
import 'admin/admin_dashboard.dart'; // Import du dashboard admin
import 'pages/payment_page.dart'; // Import de la page de paiement
import 'screens/simple_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await ProductService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()..loadCart()),
      ],
      child: MaterialApp(
        title: 'Restaurant App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const LoginPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/admin': (context) => const AdminHome(),
          '/admin/burger': (context) => const BurgerAdminPage(),
          '/admin/pizza': (context) => const PizzaAdminPage(),
          '/admin/boisson': (context) => const BoissonAdminPage(),
          '/admin/dessert': (context) => const DessertAdminPage(),
          '/admin/sushi': (context) => const SushiAdminPage(),
          '/admin/entree': (context) => const EntreeAdminPage(),
          '/admin_product': (context) => const AdminProductPage(title: 'Gestion des Produits', category: 'burger'),
          '/admin/users': (context) => const SimpleUsersScreen(),
          '/inscription': (context) => const InscriptionPage(),
          '/forgot_password': (context) => const ForgotPasswordPage(),
          '/burger': (context) => const BurgerPage(),
          '/pizza': (context) => const PizzaPage(),
          '/boisson': (context) => const BoissonPage(),
          '/dessert': (context) => const DessertPage(),
          '/sushi': (context) => const SushiPage(),
          '/entree': (context) => const EntreePage(),
          '/payment': (context) => PaymentPage(totalAmount: 0.0),
        },
      ),
    );
  }
}

class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          // L'utilisateur est connecté, vérifions son rôle
          return FutureBuilder<String?>(
            future: Future.value(AuthService.getCurrentUserRole()),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  ),
                );
              }

              // Afficher un message de débogage pour voir le rôle
              print('Rôle détecté: ${roleSnapshot.data}');

              // Redirection basée sur le rôle
              if (roleSnapshot.data == 'admin') {
                print('Redirection vers l\'interface admin');
                // Redirection directe vers admin_product_page.dart au lieu de AdminHome
                return const AdminProductPage(
                  title: 'Gestion des Produits',
                  category: 'burger', // Catégorie par défaut
                );
              }
              print('Redirection vers l\'interface client');
              return const HomePage();  
            },
          );
        }

        // L'utilisateur n'est pas connecté
        return const LoginPage();
      },
    );
  }
}
