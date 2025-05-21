import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';

class AdminProductPage extends StatefulWidget {
  final String title;
  final String category;

  const AdminProductPage({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  List<Product> _products = [];
  bool _isEditing = false;
  String? _currentEditingId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.getProducts(widget.category);
      setState(() => _products = products);
    } catch (e) {
      _showError('Erreur lors du chargement des produits: $e');
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
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'category': widget.category,
        'image': _imageFile!.path,
      };

      final success = await ProductService.addProduct(productData);
      
      if (success) {
        _resetForm();
        
        // Vérifier si c'est un produit de test/démo
        if (_nameController.text.contains('test') || 
            _nameController.text.toLowerCase().contains('demo')) {
          _showSuccess('Produit ajouté en MODE DÉMO (pas de serveur)');
        } else {
          await _loadProducts();
          _showSuccess('Produit ajouté avec succès');
        }
        // Ne pas rediriger vers login
      } else {
        _showError('Erreur lors de l\'ajout du produit');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    setState(() => _isLoading = true);
    try {
      final success = await ProductService.deleteProduct(id);
      if (success) {
        await _loadProducts();
        _showSuccess('Produit supprimé avec succès');
      } else {
        _showError('Erreur lors de la suppression');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProduct(Product product) async {
    setState(() {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      // Réinitialiser l'image car on ne peut pas récupérer l'image
      _imageFile = null; 
    });

    // Faire défiler jusqu'au formulaire
    // et indiquer à l'utilisateur qu'il peut éditer
    _showSuccess('Modifiez les informations du produit puis cliquez sur "Mettre à jour"');
    
    // Remplacer le bouton "Ajouter" par "Mettre à jour"
    setState(() {
      _isEditing = true;
      _currentEditingId = product.id;
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('Veuillez sélectionner une image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'category': widget.category,
        'image': _imageFile!.path,
        'id': _currentEditingId,
      };

      // Si c'est un produit de démo, utiliser le mode démo pour la mise à jour
      final isDemo = _nameController.text.contains('test') || 
                    _nameController.text.toLowerCase().contains('demo') ||
                    (_currentEditingId != null && _currentEditingId!.startsWith('demo'));

      final success = isDemo ? true : await ProductService.updateProduct(_currentEditingId!, productData);
      
      if (success) {
        _resetForm();
        
        if (isDemo) {
          _showSuccess('Produit mis à jour en MODE DÉMO (pas de serveur)');
        } else {
          await _loadProducts();
          _showSuccess('Produit mis à jour avec succès');
        }

        // Retourner à l'état d'ajout
        setState(() {
          _isEditing = false;
          _currentEditingId = null;
        });
      } else {
        _showError('Erreur lors de la mise à jour du produit');
      }
    } catch (e) {
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
    setState(() {
      _imageFile = null;
      // En cas d'annulation d'édition, revenir au mode d'ajout
      if (_isEditing) {
        _isEditing = false;
        _currentEditingId = null;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.white],
            stops: [0.0, 0.8],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Formulaire d'ajout
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom du produit',
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
                                      labelText: 'Prix',
                                      border: OutlineInputBorder(),
                                      prefixText: '€ ',
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                  if (_imageFile != null) ...[
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : (_isEditing ? _updateProduct : _addProduct),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isEditing ? Colors.green : Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(_isEditing ? 'Mettre à jour le produit' : 'Ajouter le produit'),
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _resetForm,
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Annuler la modification'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Liste des produits
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Liste des produits',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_isLoading)
                                  const Center(child: CircularProgressIndicator())
                                else if (_products.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Aucun produit disponible'),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _products.length,
                                    separatorBuilder: (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final product = _products[index];
                                      return ListTile(
                                        leading: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: _buildProductImage(product),
                                          ),
                                        ),
                                        title: Text(product.name),
                                        subtitle: Text(
                                          '${product.price.toStringAsFixed(2)} €\n${product.description}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => _editProduct(product),
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _deleteProduct(product.id),
                                              color: Colors.red,
                                            ),
                                          ],
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
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildProductImage(Product product) {
    if (product.imageUrl.startsWith('/data/') || product.imageUrl.startsWith('/storage/')) {
      return Image.file(
        File(product.imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) {
          print('Erreur d\'affichage d\'image locale: $err');
          return Icon(Icons.broken_image);
        },
      );
    }
    
    if (product.imageUrl.isEmpty || product.imageUrl.startsWith('assets')) {
      return Image.asset(
        'assets/images/${product.category}.jpg',
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => Icon(Icons.image),
      );
    }
    
    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) => Icon(Icons.image),
    );
  }
} 