import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/simple_user_service.dart';

class SimpleUsersScreen extends StatefulWidget {
  const SimpleUsersScreen({Key? key}) : super(key: key);

  @override
  _SimpleUsersScreenState createState() => _SimpleUsersScreenState();
}

class _SimpleUsersScreenState extends State<SimpleUsersScreen> {
  bool _isLoading = true;
  List<User> _admins = [];
  List<User> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await SimpleUserService.getUsersList();
      setState(() {
        _admins = users['admins'] ?? [];
        _clients = users['clients'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Widget _buildUserList(String title, List<User> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.role == 'admin' ? Colors.orange : Colors.blue,
                  child: Text(
                    user.email[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user.email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user.fullName ?? 'Non renseigné'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role == 'admin' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: user.role == 'admin' ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildUserList('Administrateurs', _admins),
                    const Divider(height: 32),
                    _buildUserList('Clients', _clients),
                  ],
                ),
              ),
            ),
    );
  }
} 