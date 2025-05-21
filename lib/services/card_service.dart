import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import 'auth_service.dart';

class CardService {
  static SharedPreferences? _prefs;
  static const String _cardsKey = 'user_cards';

  // Initialiser SharedPreferences
  static Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Récupérer toutes les cartes d'un utilisateur
  static Future<List<BankCard>> getUserCards() async {
    if (_prefs == null) await _initPrefs();
    
    try {
      final cardsJson = _prefs?.getString(_cardsKey);
      if (cardsJson == null) return [];

      final List<dynamic> data = json.decode(cardsJson);
      return data.map((json) => BankCard.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des cartes: $e');
      return [];
    }
  }

  // Ajouter une nouvelle carte
  static Future<bool> addCard(BankCard card) async {
    try {
      if (_prefs == null) await _initPrefs();

      // Récupérer les cartes existantes
      final cards = await getUserCards();
      
      // Générer un ID unique pour la nouvelle carte
      final newCard = BankCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardNumber: card.cardNumber,
        cardHolder: card.cardHolder,
        expiryDate: card.expiryDate,
        cvv: card.cvv,
        isDefault: cards.isEmpty, // La première carte est par défaut
      );

      // Ajouter la nouvelle carte
      cards.add(newCard);

      // Sauvegarder les cartes
      await _prefs?.setString(_cardsKey, json.encode(cards.map((c) => c.toJson()).toList()));
      
      print('Carte ajoutée avec succès: ${newCard.cardNumber}');
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout de la carte: $e');
      return false;
    }
  }

  // Supprimer une carte
  static Future<bool> deleteCard(String cardId) async {
    try {
      if (_prefs == null) await _initPrefs();

      // Récupérer les cartes existantes
      final cards = await getUserCards();
      
      // Trouver la carte à supprimer
      final cardIndex = cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;

      // Vérifier si c'est la carte par défaut
      final isDefault = cards[cardIndex].isDefault;

      // Supprimer la carte
      cards.removeAt(cardIndex);

      // Si c'était la carte par défaut et qu'il reste des cartes, définir la première comme par défaut
      if (isDefault && cards.isNotEmpty) {
        cards[0] = BankCard(
          id: cards[0].id,
          cardNumber: cards[0].cardNumber,
          cardHolder: cards[0].cardHolder,
          expiryDate: cards[0].expiryDate,
          cvv: cards[0].cvv,
          isDefault: true,
        );
      }

      // Sauvegarder les cartes
      await _prefs?.setString(_cardsKey, json.encode(cards.map((c) => c.toJson()).toList()));
      
      print('Carte supprimée avec succès: $cardId');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la carte: $e');
      return false;
    }
  }

  // Définir une carte comme carte par défaut
  static Future<bool> setDefaultCard(String cardId) async {
    try {
      if (_prefs == null) await _initPrefs();

      // Récupérer les cartes existantes
      final cards = await getUserCards();
      
      // Trouver la carte à définir comme par défaut
      final cardIndex = cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;

      // Mettre à jour toutes les cartes
      for (int i = 0; i < cards.length; i++) {
        cards[i] = BankCard(
          id: cards[i].id,
          cardNumber: cards[i].cardNumber,
          cardHolder: cards[i].cardHolder,
          expiryDate: cards[i].expiryDate,
          cvv: cards[i].cvv,
          isDefault: i == cardIndex,
        );
      }

      // Sauvegarder les cartes
      await _prefs?.setString(_cardsKey, json.encode(cards.map((c) => c.toJson()).toList()));
      
      print('Carte définie comme par défaut: $cardId');
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la carte par défaut: $e');
      return false;
    }
  }
} 