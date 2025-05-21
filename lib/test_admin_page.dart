import 'package:flutter/material.dart';
import 'admin/admin_product_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  // Définir le rôle administrateur pour le test
  await AuthService.setUserRole('admin');
  runApp(const TestAdminProductPage());
}

class TestAdminProductPage extends StatelessWidget {
  const TestAdminProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Admin Product Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminProductPage(
        title: 'Test Burger Admin',
        category: 'burger',
      ),
    );
  }
} 