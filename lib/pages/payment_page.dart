import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/card.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import 'dart:math';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({Key? key, required this.totalAmount}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;
  List<BankCard> _savedCards = [];
  BankCard? _selectedCard;
  bool _useNewCard = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    final cards = await CardService.getUserCards();
    setState(() {
      _savedCards = cards;
      if (cards.isNotEmpty) {
        _selectedCard = cards.firstWhere((card) => card.isDefault, orElse: () => cards.first);
      }
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final userEmail = AuthService.getCurrentUserEmail() ?? 'utilisateur@exemple.com';
      final orderId = OrderService.generateOrderId();
      
      final orderItems = cart.items.values
          .map((item) => OrderItem.fromCartItem(item))
          .toList();
      
      String paymentMethod;
      if (_useNewCard) {
        // Si c'est une nouvelle carte, on peut l'enregistrer
        final newCard = BankCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cardNumber: _cardNumberController.text.replaceAll(' ', ''),
          cardHolder: _cardHolderController.text,
          expiryDate: _expiryDateController.text,
          cvv: _cvvController.text,
          isDefault: _savedCards.isEmpty,
        );
        
        await CardService.addCard(newCard);
        paymentMethod = 'Carte bancaire (terminée par ${newCard.maskedCardNumber.substring(newCard.maskedCardNumber.length - 4)})';
      } else {
        paymentMethod = 'Carte bancaire (terminée par ${_selectedCard!.maskedCardNumber.substring(_selectedCard!.maskedCardNumber.length - 4)})';
      }
      
      final order = Order(
        id: orderId,
        userEmail: userEmail,
        date: DateTime.now(),
        items: orderItems,
        total: widget.totalAmount,
        status: 'En préparation',
        paymentMethod: paymentMethod,
        deliveryAddress: _addressController.text,
      );
      
      await Future.delayed(const Duration(seconds: 2));
      await OrderService.saveOrder(order);
      await cart.clear();

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Paiement réussi'),
          content: const Text('Votre commande a été validée et sera livrée prochainement. Vous pouvez suivre votre commande dans votre historique.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erreur lors du traitement du paiement: $e');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erreur de paiement'),
          content: const Text('Une erreur est survenue lors du traitement de votre paiement. Veuillez réessayer.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Montant à payer
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Montant à payer',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.totalAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Adresse de livraison
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse de livraison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse complète',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre adresse de livraison';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Sélection de la carte
              if (_savedCards.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Carte de paiement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._savedCards.map((card) => RadioListTile<BankCard>(
                          title: Text('Carte terminant par ${card.maskedCardNumber.substring(card.maskedCardNumber.length - 4)}'),
                          subtitle: Text('Expire le ${card.expiryDate}'),
                          value: card,
                          groupValue: _selectedCard,
                          onChanged: (value) {
                            setState(() {
                              _selectedCard = value;
                              _useNewCard = false;
                            });
                          },
                        )),
                        RadioListTile<bool>(
                          title: const Text('Utiliser une nouvelle carte'),
                          value: true,
                          groupValue: _useNewCard,
                          onChanged: (value) {
                            setState(() {
                              _useNewCard = value!;
                              _selectedCard = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Nouvelle carte (si sélectionnée ou pas de cartes enregistrées)
              if (_useNewCard || _savedCards.isEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations de paiement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Titulaire de la carte
                        TextFormField(
                          controller: _cardHolderController,
                          decoration: const InputDecoration(
                            labelText: 'Titulaire de la carte',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom du titulaire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Numéro de carte
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de carte',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CreditCardInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le numéro de carte';
                            }
                            final cleanedValue = value.replaceAll(' ', '');
                            if (cleanedValue.length < 16) {
                              return 'Le numéro de carte doit contenir 16 chiffres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Date d'expiration et CVV
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Date d\'expiration (MM/AA)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez la date';
                                  }
                                  if (value.length < 5) {
                                    return 'Format invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: _cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Requis';
                                  }
                                  if (value.length < 3) {
                                    return 'Invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Bouton de paiement
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Payer maintenant',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Formatter pour formater le numéro de carte avec des espaces tous les 4 chiffres
class _CreditCardInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final cleanText = newValue.text.replaceAll(' ', '');
    final parts = <String>[];
    
    for (var i = 0; i < cleanText.length; i += 4) {
      final end = i + 4 > cleanText.length ? cleanText.length : i + 4;
      parts.add(cleanText.substring(i, end));
    }
    
    final formattedText = parts.join(' ');
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText.length,
      ),
    );
  }
}

// Formatter pour formater la date d'expiration (MM/AA)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final cleanText = newValue.text.replaceAll('/', '');
    var formattedText = cleanText;
    
    if (cleanText.length >= 2) {
      formattedText = cleanText.substring(0, 2) + '/' + cleanText.substring(2);
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText.length,
      ),
    );
  }
} 