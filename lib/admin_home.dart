import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'services/auth_service.dart';
import 'pages/product_management.dart';
import 'admin/burger_admin.dart';
import 'admin/pizza_admin.dart';
import 'admin/boisson_admin.dart';
import 'admin/dessert_admin.dart';
import 'admin/sushi_admin.dart';
import 'admin/entree_admin.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'sushi';
  File? _imageFile;
  bool _isLoading = false;
  int _selectedIndex = 0;

  final List<String> _categories = [
    'sushi',
    'pizza',
    'burger',
    'dessert',
    'entree',
    'boisson'
  ];

  final List<Widget> _pages = [
    const BurgerAdminPage(),
    const PizzaAdminPage(),
    const SushiAdminPage(),
    const DessertAdminPage(),
    const BoissonAdminPage(),
    const EntreeAdminPage(),
  ];

  final List<String> _titles = [
    'Gestion des Burgers',
    'Gestion des Pizzas',
    'Gestion des Sushis',
    'Gestion des Desserts',
    'Gestion des Boissons',
    'Gestion des Entrées',
  ];

  Future<String> _uploadImage() async {
    if (_imageFile == null) return '';

    try {
      print('Début du téléchargement de l\'image');
      
      // Vérifier si le fichier existe
      if (!await _imageFile!.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }

      // Vérifier la taille du fichier
      final fileSize = await _imageFile!.length();
      print('Taille du fichier: $fileSize bytes');
      
      if (fileSize > 5 * 1024 * 1024) { // 5MB max
        throw Exception('L\'image est trop grande (maximum 5MB)');
      }

      // Créer un nom de fichier unique
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'product_$timestamp${path.extension(_imageFile!.path)}';

      // Créer un formulaire multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/restaurant_api/upload_image.php'),
      );

      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          filename: fileName,
        ),
      );

      // Envoyer la requête
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonResponse = json.decode(responseString);

      if (response.statusCode == 200 && jsonResponse['success']) {
        print('Image téléchargée avec succès');
        return jsonResponse['image_url'];
      } else {
        throw Exception('Erreur lors du téléchargement: ${jsonResponse['message']}');
      }

    } catch (e) {
      print('ERREUR DÉTAILLÉE: $e');
      throw Exception('Erreur lors du téléchargement: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Afficher une boîte de dialogue pour choisir la source
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choisir une source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galerie'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        print('Image sélectionnée: ${image.path}');
                        final File file = File(image.path);
                        setState(() {
                          _imageFile = file;
                        });
                        print('Taille de l\'image: ${await file.length()} bytes');
                      } else {
                        print('Aucune image sélectionnée');
                      }
                    } catch (e) {
                      print('Erreur lors de la sélection de l\'image: $e');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Appareil photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        print('Photo prise: ${image.path}');
                        setState(() {
                          _imageFile = File(image.path);
                        });
                      }
                    } catch (e) {
                      print('Erreur lors de la prise de photo: $e');
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Erreur lors de l\'ouverture du sélecteur d\'images: $e');
    }
  }

  Future<void> _addProduct() async {
    try {
      if (!_formKey.currentState!.validate()) {
        throw Exception('Veuillez remplir tous les champs correctement');
      }

      if (_imageFile == null) {
        throw Exception('Veuillez sélectionner une image');
      }

      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours...'),
          duration: Duration(seconds: 2),
        ),
      );

      final imageUrl = await _uploadImage();

      final product = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'image_url': imageUrl,
        'category': _selectedCategory,
      };

      // Envoyer les données du produit à l'API
      final response = await http.post(
        Uri.parse('http://localhost/restaurant_api/add_product.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produit ajouté avec succès!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            _formKey.currentState!.reset();
            _nameController.clear();
            _descriptionController.clear();
            _priceController.clear();
            setState(() {
              _imageFile = null;
            });
          }
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Erreur lors de l\'ajout du produit');
      }

    } catch (e) {
      print('ERREUR lors de l\'ajout du produit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        backgroundColor: Colors.deepOrange,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'ADMINISTRATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'MODE ADMIN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lunch_dining),
              title: const Text('Burgers'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_pizza),
              title: const Text('Pizzas'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.set_meal),
              title: const Text('Sushis'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Desserts'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_bar),
              title: const Text('Boissons'),
              selected: _selectedIndex == 4,
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Entrées'),
              selected: _selectedIndex == 5,
              onTap: () {
                _onItemTapped(5);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Ajouter un ${_categories[_selectedIndex]}'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une description';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Prix (€)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un prix';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Sélectionner une image'),
                        ),
                        if (_imageFile != null) ...[
                          const SizedBox(height: 10),
                          Image.file(
                            _imageFile!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _addProduct();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Ajouter'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
