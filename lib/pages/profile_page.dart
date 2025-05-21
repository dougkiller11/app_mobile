import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/card.dart';
import '../services/card_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  File? _profileImage;
  bool _isLoading = false;
  bool _isEditing = false;
  String _userEmail = '';
  List<BankCard> _cards = [];
  bool _isLoadingCards = false;
  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Contrôleurs pour la modification du mot de passe
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCards();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer l'email de l'utilisateur connecté
      final userEmail = AuthService.getCurrentUserEmail() ?? 'utilisateur@exemple.com';
      _userEmail = userEmail;
      
      // Charger le profil depuis le stockage local
      final userProfile = await UserProfileService.getUserProfileOrDefault(userEmail);
      
      setState(() {
        _emailController.text = userProfile.email;
        _nameController.text = userProfile.name;
        _phoneController.text = userProfile.phone;
        _addressController.text = userProfile.address;
        
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
      // En cas d'erreur, utiliser des données par défaut
      _emailController.text = _userEmail;
      _nameController.text = 'Utilisateur';
      _phoneController.text = '';
      _addressController.text = '';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _profileImage = File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir une image de profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Option Galerie
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _pickImage();
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          size: 32,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Galerie'),
                  ],
                ),
                // Option Appareil photo
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _takePhoto();
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Appareil photo'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Sauvegarder le profil dans SharedPreferences
      await UserProfileService.updateUserProfile(
        email: _userEmail,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        profileImagePath: _profileImage?.path,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCards() async {
    setState(() => _isLoadingCards = true);
    try {
      final cards = await CardService.getUserCards();
      setState(() {
        _cards = cards;
        _isLoadingCards = false;
      });
    } catch (e) {
      setState(() => _isLoadingCards = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des cartes: $e')),
      );
    }
  }

  // Formater le numéro de carte
  String _formatCardNumber(String input) {
    // Supprimer tous les espaces existants
    String cleaned = input.replaceAll(' ', '');
    // Limiter à 16 chiffres
    cleaned = cleaned.substring(0, cleaned.length > 16 ? 16 : cleaned.length);
    // Ajouter un espace tous les 4 chiffres
    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cleaned[i];
    }
    return formatted;
  }

  // Formater la date d'expiration
  String _formatExpiryDate(String input) {
    // Supprimer tous les caractères non numériques
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    // Limiter à 4 chiffres
    cleaned = cleaned.substring(0, cleaned.length > 4 ? 4 : cleaned.length);
    
    // Ajouter le slash après les 2 premiers chiffres
    if (cleaned.length > 2) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    }
    return cleaned;
  }

  Future<void> _addCard() async {
    if (!_cardFormKey.currentState!.validate()) return;
    try {
      final card = BankCard(
        id: '',
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
          key: _cardFormKey,
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
                  onChanged: (value) {
                    // Formater le numéro pendant la saisie
                    final formatted = _formatCardNumber(value);
                    if (formatted != value) {
                      _cardNumberController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de carte';
                    }
                    // Vérifier qu'il y a exactement 16 chiffres (sans les espaces)
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
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Formater la date pendant la saisie
                    final formatted = _formatExpiryDate(value);
                    if (formatted != value) {
                      _expiryDateController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date d\'expiration';
                    }
                    // Vérifier le format MM/YY
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Format invalide (MM/YY)';
                    }
                    // Vérifier que le mois est valide (01-12)
                    final month = int.parse(value.substring(0, 2));
                    if (month < 1 || month > 12) {
                      return 'Mois invalide (01-12)';
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
                  maxLength: 3,
                  onChanged: (value) {
                    // Limiter à 3 chiffres
                    if (value.length > 3) {
                      _cvvController.value = TextEditingValue(
                        text: value.substring(0, 3),
                        selection: TextSelection.collapsed(offset: 3),
                      );
                    }
                  },
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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le mot de passe'),
        content: SingleChildScrollView(
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ancien mot de passe
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showCurrentPassword = !_showCurrentPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe actuel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Nouveau mot de passe
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNewPassword = !_showNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nouveau mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirmation du nouveau mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer le nouveau mot de passe';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Les mots de passe ne correspondent pas';
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
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.of(ctx).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_currentPasswordController.text.isEmpty ||
                  _newPasswordController.text.isEmpty ||
                  _confirmPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }

              if (_newPasswordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                );
                return;
              }

              try {
                final result = await AuthService.changePassword(
                  _currentPasswordController.text,
                  _newPasswordController.text,
                );

                if (result['success']) {
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mot de passe modifié avec succès')),
                    );
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Erreur lors de la modification du mot de passe')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de la modification du mot de passe')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.orange,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo de profil
                  Center(
                    child: Stack(
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
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _showImageSourceOptions,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Formulaire des informations
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nom complet
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom complet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            enabled: _isEditing,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                            enabled: false, // L'email ne peut pas être modifié
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Téléphone
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                            enabled: _isEditing,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Adresse
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Adresse',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.home),
                            enabled: _isEditing,
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre adresse';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Bouton de modification du mot de passe
                        if (!_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(Icons.lock),
                              label: const Text('Modifier le mot de passe'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.orange),
                                foregroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Boutons de sauvegarde / annulation
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _isEditing = false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Enregistrer'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Section Cartes bancaires
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
                          if (_isLoadingCards)
                            const Center(child: CircularProgressIndicator())
                          else if (_cards.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune carte enregistrée',
                                    style: TextStyle(
                                      color: Colors.grey,
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
} 