import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({Key? key}) : super(key: key);

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  bool _isLoading = false;
  List<Order> _orders = [];
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer l'email de l'utilisateur
      final userEmail = AuthService.getCurrentUserEmail() ?? 'utilisateur@exemple.com';
      _userEmail = userEmail;
      
      // Charger les commandes depuis le service
      final orders = await OrderService.getOrdersByEmail(userEmail);
      
      // Si aucune commande n'est trouvée et que c'est la première utilisation,
      // créer des exemples de commandes pour la démonstration
      if (orders.isEmpty) {
        final dummyOrders = _createDummyOrders(userEmail);
        for (var order in dummyOrders) {
          await OrderService.saveOrder(order);
        }
        _orders = dummyOrders;
      } else {
        _orders = orders;
      }
      
      // Trier les commandes par date (plus récentes en premier)
      _orders.sort((a, b) => b.date.compareTo(a.date));
      
    } catch (e) {
      print('Erreur lors du chargement des commandes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fonction pour créer des commandes d'exemple
  List<Order> _createDummyOrders(String email) {
    return [
      Order(
        id: 'ORD-001',
        userEmail: email,
        date: DateTime.now().subtract(const Duration(days: 2)),
        total: 25.50,
        status: 'Livré',
        items: [
          OrderItem(
            productId: 'b1',
            name: 'Burger Classic', 
            quantity: 1, 
            price: 9.50,
          ),
          OrderItem(
            productId: 'f1',
            name: 'Frites', 
            quantity: 1, 
            price: 3.50,
          ),
          OrderItem(
            productId: 'c1',
            name: 'Coca-Cola', 
            quantity: 2, 
            price: 3.00,
          ),
          OrderItem(
            productId: 'd1',
            name: 'Dessert du jour', 
            quantity: 1, 
            price: 6.50,
          ),
        ],
        paymentMethod: 'Carte bancaire',
        deliveryAddress: '123 rue de Paris, 75001 Paris',
      ),
      Order(
        id: 'ORD-002',
        userEmail: email,
        date: DateTime.now().subtract(const Duration(days: 10)),
        total: 32.90,
        status: 'Livré',
        items: [
          OrderItem(
            productId: 'p1',
            name: 'Pizza Margherita', 
            quantity: 1, 
            price: 12.90,
          ),
          OrderItem(
            productId: 's1',
            name: 'Salade César', 
            quantity: 1, 
            price: 8.50,
          ),
          OrderItem(
            productId: 't1',
            name: 'Tiramisu', 
            quantity: 1, 
            price: 5.50,
          ),
          OrderItem(
            productId: 'e1',
            name: 'Eau minérale', 
            quantity: 2, 
            price: 3.00,
          ),
        ],
        paymentMethod: 'Carte bancaire',
        deliveryAddress: '123 rue de Paris, 75001 Paris',
      ),
      Order(
        id: 'ORD-003',
        userEmail: email,
        date: DateTime.now().subtract(const Duration(hours: 3)),
        total: 18.90,
        status: 'En préparation',
        items: [
          OrderItem(
            productId: 'b2',
            name: 'Burger Cheese', 
            quantity: 1, 
            price: 10.90,
          ),
          OrderItem(
            productId: 'f1',
            name: 'Frites', 
            quantity: 1, 
            price: 3.50,
          ),
          OrderItem(
            productId: 'c1',
            name: 'Coca-Cola', 
            quantity: 1, 
            price: 4.50,
          ),
        ],
        paymentMethod: 'Carte bancaire',
        deliveryAddress: '123 rue de Paris, 75001 Paris',
      ),
    ];
  }

  // Fonction pour annuler une commande
  Future<void> _cancelOrder(String orderId) async {
    try {
      final success = await OrderService.updateOrderStatus(_userEmail, orderId, 'Annulé');
      
      if (success) {
        // Recharger les commandes après l'annulation
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande annulée avec succès'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de l\'annulation de la commande: $e');
    }
  }

  // Fonction pour marquer une commande comme livrée
  Future<void> _markAsDelivered(String orderId) async {
    try {
      final success = await OrderService.updateOrderStatus(_userEmail, orderId, 'Livré');
      
      if (success) {
        // Recharger les commandes après la mise à jour
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande marquée comme livrée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de la commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Impossible de mettre à jour le statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Titre explicatif
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Appuyez sur une commande pour voir les détails',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    // Liste des commandes
                    Expanded(
                      child: ListView.builder(
                        itemCount: _orders.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande à afficher',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    
    // Déterminer la couleur du statut
    Color statusColor;
    IconData statusIcon;
    switch (order.status.toLowerCase()) {
      case 'livré':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'en préparation':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'annulé':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête de la carte avec statut à droite
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Commandé le ${dateFormat.format(order.date)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            order.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (order.status.toLowerCase() == 'en préparation') ...[
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Marquer comme livré',
                        onPressed: () => _markAsDelivered(order.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Annuler la commande',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Annuler la commande'),
                              content: const Text('Voulez-vous vraiment annuler cette commande ?'),
                              actions: [
                                TextButton(
                                  child: const Text('Non'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text('Oui'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _cancelOrder(order.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.keyboard_arrow_down),
          ),
          
          // Détails de la commande
          ExpansionTile(
            title: const Text(
              'Détails de la commande',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            initiallyExpanded: false,
            backgroundColor: Colors.grey[50],
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const Divider(),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${(item.price * item.quantity).toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(),
              if (order.deliveryAddress != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Livré à: ${order.deliveryAddress}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.paymentMethod != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Payé par: ${order.paymentMethod}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${order.total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.status.toLowerCase() == 'en préparation') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Annuler la commande'),
                              content: const Text('Voulez-vous vraiment annuler cette commande ?'),
                              actions: [
                                TextButton(
                                  child: const Text('Non'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text('Oui'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _cancelOrder(order.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _markAsDelivered(order.id);
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text('Marquer comme livré'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
} 