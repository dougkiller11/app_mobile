import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedUsers = await UserService.getAllUsers();
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      _showMessage('Erreur lors du chargement des utilisateurs: $e', isError: true);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addUser() async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => const UserFormDialog(),
    );

    if (result != null) {
      try {
        final response = await AuthService.register(
          email: result.email,
          password: 'password123', // Mot de passe temporaire
          fullName: result.fullName ?? result.email, // Utiliser l'email comme fallback
          role: result.role,
        );

        if (response['success'] == true) {
          _showMessage('Utilisateur ajouté avec succès');
          _loadUsers(); // Recharger la liste des utilisateurs
        } else {
          _showMessage(response['message'] ?? 'Erreur lors de l\'ajout de l\'utilisateur', isError: true);
        }
      } catch (e) {
        _showMessage('Erreur: $e', isError: true);
      }
    }
  }

  Future<void> _editUser(User user) async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );

    if (result != null) {
      try {
        final response = await UserService.updateUser(result);
        if (response['success'] == true) {
          _showMessage('Utilisateur modifié avec succès');
          _loadUsers(); // Recharger la liste des utilisateurs
        } else {
          _showMessage(response['message'] ?? 'Erreur lors de la modification de l\'utilisateur', isError: true);
        }
      } catch (e) {
        _showMessage('Erreur: $e', isError: true);
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'utilisateur ${user.fullName ?? user.email} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await UserService.deleteUser(user.id);
        if (response['success'] == true) {
          _showMessage('Utilisateur supprimé avec succès');
          _loadUsers(); // Recharger la liste des utilisateurs
        } else {
          _showMessage(response['message'] ?? 'Erreur lors de la suppression de l\'utilisateur', isError: true);
        }
      } catch (e) {
        _showMessage('Erreur: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[50]!, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.role == 'admin' ? Colors.orange : Colors.blue,
                        child: Text((user.fullName ?? user.email)[0].toUpperCase()),
                      ),
                      title: Text(user.fullName ?? user.email),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(
                            'Rôle: ${user.role == 'admin' ? 'Administrateur' : 'Client'}',
                            style: TextStyle(
                              color: user.role == 'admin' ? Colors.orange : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editUser(user),
                            color: Colors.orange,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(user),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({Key? key, this.user}) : super(key: key);

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _selectedRole = widget.user?.role ?? 'client';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Ajouter un utilisateur' : 'Modifier l\'utilisateur'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un email';
                }
                if (!value.contains('@')) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Client')),
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final user = User(
                id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                email: _emailController.text,
                fullName: _nameController.text,
                role: _selectedRole,
                createdAt: widget.user?.createdAt ?? DateTime.now(),
                lastLogin: widget.user?.lastLogin,
              );
              Navigator.pop(context, user);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
} 