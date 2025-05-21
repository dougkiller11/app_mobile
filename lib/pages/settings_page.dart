import 'dart:io';
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'purchase_history_page.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class ProfileMenuPage extends StatefulWidget {
  const ProfileMenuPage({Key? key}) : super(key: key);

  @override
  State<ProfileMenuPage> createState() => _ProfileMenuPageState();
}

class _ProfileMenuPageState extends State<ProfileMenuPage> {
  bool _isLoading = true;
  String _userName = 'Utilisateur';
  String _userEmail = '';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer l'email de l'utilisateur connecté
      final userEmail = AuthService.getCurrentUserEmail() ?? 'utilisateur@exemple.com';
      final userProfile = await UserProfileService.getUserProfileOrDefault(userEmail);
      
      setState(() {
        _userName = userProfile.name;
        _userEmail = userProfile.email;
        
        // Charger l'image de profil si elle existe
        if (userProfile.profileImagePath != null) {
          final imageFile = File(userProfile.profileImagePath!);
          if (imageFile.existsSync()) {
            _profileImage = imageFile;
          }
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Photo de profil en haut
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) as ImageProvider
                        : const AssetImage('assets/images/default_profile.png'),
                    child: _profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Options du menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Section Informations personnelles
                  ProfileMenuCard(
                    icon: Icons.person,
                    title: 'Mes informations',
                    subtitle: 'Modifier mes informations personnelles',
                    onTap: () async {
                      // Navigation vers le profil et rechargement des données au retour
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                      _loadUserData(); // Recharger les données après modification
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Section Achats
                  ProfileMenuCard(
                    icon: Icons.receipt_long,
                    title: 'Mes commandes',
                    subtitle: 'Consulter mon historique d\'achats',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Section Déconnexion
                  ProfileMenuCard(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    subtitle: 'Se déconnecter de l\'application',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              child: const Text('Annuler'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            TextButton(
                              child: const Text('Déconnexion'),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await AuthService.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les cartes du menu profil
class ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileMenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 