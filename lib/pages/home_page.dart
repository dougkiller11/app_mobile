import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/role_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userEmail;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    _userEmail = AuthService.getCurrentUserEmail();
    _isAdmin = await AuthService.isAdmin();
    if (mounted) setState(() {});
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurant Lux',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _isAdmin ? Colors.orange : Colors.blue,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: RoleIndicator(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _isAdmin ? Colors.orange.shade100 : Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 100,
                color: _isAdmin ? Colors.orange : Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                'Bienvenue${_userEmail != null ? ' $_userEmail' : ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isAdmin ? 'Mode Administrateur' : 'Mode Client',
                style: TextStyle(
                  fontSize: 18,
                  color: _isAdmin ? Colors.orange : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              if (_isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Accéder au Panel Admin',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 