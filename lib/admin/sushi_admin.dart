import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';

class SushiAdminPage extends StatefulWidget {
  const SushiAdminPage({super.key});

  @override
  State<SushiAdminPage> createState() => _SushiAdminPageState();
}

class _SushiAdminPageState extends State<SushiAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.getProducts('sushi');
      setState(() => _products = products);
    } catch (e) {
      _showError('Erreur lors du chargement des sushis: $e');
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
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('Veuillez sélectionner une image');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String imagePath = _imageFile!.path;
      if (!imagePath.toLowerCase().endsWith('.jpg') && 
          !imagePath.toLowerCase().endsWith('.jpeg') && 
          !imagePath.toLowerCase().endsWith('.png')) {
        _showError('Format d\'image non supporté. Utilisez JPG, JPEG ou PNG.');
        return;
      }

      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': 'sushi',
        'image': imagePath,
      };

      print('Ajout d\'un nouveau sushi avec l\'image: $imagePath');

      final success = await ProductService.addProduct(productData);
      if (success) {
        _resetForm();
        await _loadProducts();
        _showSuccess('Sushi ajouté avec succès');
      } else {
        _showError('Erreur lors de l\'ajout du sushi');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      setState(() => _isLoading = true);
      print('Tentative de suppression du produit avec l\'ID: $id');
      
      final success = await ProductService.deleteProduct(id);
      if (success) {
        print('Produit supprimé avec succès');
        await _loadProducts();
        _showSuccess('Sushi supprimé avec succès');
      } else {
        print('Échec de la suppression du produit');
        _showError('Erreur lors de la suppression');
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() => _imageFile = null);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    print('Construction de l\'image avec URL: $imageUrl');
    
    if (imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[300],
        child: const Icon(Icons.set_meal, size: 30, color: Colors.white),
      );
    }

    if (imageUrl.startsWith('/data/') || imageUrl.startsWith('/storage/')) {
      return Image.file(
        File(imageUrl),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image locale: $err');
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.set_meal, size: 30, color: Colors.white),
          );
        },
      );
    }

    if (imageUrl.startsWith('assets')) {
      return Image.asset(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image asset: $err');
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.set_meal, size: 30, color: Colors.white),
          );
        },
      );
    }

    return Image.network(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) {
        print('Erreur d\'affichage d\'image réseau: $err');
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[300],
          child: const Icon(Icons.set_meal, size: 30, color: Colors.white),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ajouter un nouveau sushi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du sushi',
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
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (€)',
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Sélectionner une image'),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 8),
                      Image.file(
                        _imageFile!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addProduct,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Ajouter le sushi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Liste des sushis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            const Center(child: Text('Aucun sushi disponible'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _buildProductImage(product.imageUrl),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.description}\nPrix: ${product.price.toStringAsFixed(2)}€',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(product.id),
                    ),
                  ),
                );
              },
            ),
        ],
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