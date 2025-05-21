import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProductManagementPage extends StatefulWidget {
  final String? initialCategory;
  
  const ProductManagementPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['Sushi', 'Pizza', 'Burger', 'Dessert', 'Entrée', 'Boisson'];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Sélectionner l'onglet initial si une catégorie est spécifiée
    if (widget.initialCategory != null) {
      final index = _categories.indexWhere(
        (category) => category.toLowerCase() == widget.initialCategory!.toLowerCase()
      );
      if (index != -1) {
        _tabController.animateTo(index);
      }
    }
    
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/restaurant_api/get_products.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(data['products']);
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
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
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _addProduct(String category) async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload de l'image
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'product_$timestamp${path.extension(_imageFile!.path)}';
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/restaurant_api/upload_image.php'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path, filename: fileName),
      );

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var imageResponse = json.decode(String.fromCharCodes(responseData));

      if (!imageResponse['success']) throw Exception('Erreur lors de l\'upload de l\'image');

      // Ajout du produit
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': category.toLowerCase(),
        'image_url': imageResponse['image_url'],
      };

      final productResponse = await http.post(
        Uri.parse('http://localhost/restaurant_api/add_product.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );

      final result = json.decode(productResponse.body);

      if (result['success']) {
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() => _imageFile = null);
        _loadProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit ajouté avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom du produit'),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Ce champ est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Ce champ est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Prix (€)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Ce champ est requis';
                          if (double.tryParse(value!) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Sélectionner une image'),
                      ),
                      if (_imageFile != null) ...[
                        const SizedBox(height: 8),
                        Image.file(_imageFile!, height: 100),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _addProduct(category),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Ajouter le produit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Produits ${category}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Liste des produits de la catégorie
                ...(_products
                    .where((p) => p['category'].toString().toLowerCase() == category.toLowerCase())
                    .map((product) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: product['image_url'] != null
                                ? Image.network(
                                    product['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image),
                            title: Text(product['name']),
                            subtitle: Text('${product['price']}€'),
                          ),
                        ))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
} 