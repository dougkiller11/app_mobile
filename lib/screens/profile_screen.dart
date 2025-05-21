import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/card.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<BankCard> _cards = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCards();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        setState(() {
          _user = User.fromJson(json.decode(userJson));
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadCards() async {
    try {
      setState(() => _isLoading = true);
      final cards = await CardService.getUserCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des cartes: $e')),
      );
    }
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final card = BankCard(
        id: '', // L'ID sera généré par le serveur
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        cardHolder: _cardHolderController.text,
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
      );

      await CardService.addCard(card);
      _loadCards();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte ajoutée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de la carte: $e')),
      );
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await CardService.deleteCard(cardId);
      _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de la carte: $e')),
      );
    }
  }

  Future<void> _setDefaultCard(String cardId) async {
    try {
      await CardService.setDefaultCard(cardId);
      _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte par défaut mise à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour de la carte par défaut: $e')),
      );
    }
  }

  void _showAddCardDialog() {
    _cardNumberController.clear();
    _cardHolderController.clear();
    _expiryDateController.clear();
    _cvvController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une carte'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de carte',
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de carte';
                    }
                    if (value.replaceAll(' ', '').length != 16) {
                      return 'Le numéro de carte doit contenir 16 chiffres';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _cardHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Titulaire de la carte',
                    hintText: 'JEAN DUPONT',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom du titulaire';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date d\'expiration',
                    hintText: 'MM/AA',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date d\'expiration';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Format invalide (MM/AA)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le CVV';
                    }
                    if (value.length != 3) {
                      return 'Le CVV doit contenir 3 chiffres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _addCard,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations utilisateur
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations personnelles',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(_user?.email ?? ''),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Nom complet'),
                            subtitle: Text(_user?.fullName ?? ''),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Rôle'),
                            subtitle: Text(_user?.role ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cartes bancaires
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mes cartes bancaires',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.orange,
                                onPressed: _showAddCardDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_cards.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune carte enregistrée',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _showAddCardDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Ajouter une carte'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _cards.length,
                              itemBuilder: (context, index) {
                                final card = _cards[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: card.isDefault ? Colors.green[50] : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.credit_card,
                                        color: card.isDefault ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    title: Text(
                                      card.maskedCardNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(card.cardHolder),
                                        if (card.isDefault)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Carte par défaut',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!card.isDefault)
                                          IconButton(
                                            icon: const Icon(Icons.star_border),
                                            color: Colors.orange,
                                            onPressed: () => _setDefaultCard(card.id),
                                            tooltip: 'Définir comme carte par défaut',
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                          onPressed: card.isDefault
                                              ? null
                                              : () => _deleteCard(card.id),
                                          tooltip: card.isDefault
                                              ? 'Impossible de supprimer la carte par défaut'
                                              : 'Supprimer la carte',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
} 