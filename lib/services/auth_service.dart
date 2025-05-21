import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // URL dynamique en fonction de la plateforme
  static String get baseUrl {
    // Si on est sur Android et en mode debug (émulateur)
    if (Platform.isAndroid) {
      return 'http://10.0.2.2/restaurant_api';
    }
    // Sinon (Windows, iOS, etc.)
    return 'http://localhost/restaurant_api';
  }
  
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userEmailKey = 'user_email';

  // Instance de SharedPreferences pour stocker le token
  static SharedPreferences? _prefs;

  // Initialisation de SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setUserRole(String role) async {
    print('Définition du rôle utilisateur: $role');
    await _prefs?.setString(userRoleKey, role);
    // Vérifier que le rôle a bien été enregistré
    final savedRole = _prefs?.getString(userRoleKey);
    print('Rôle enregistré dans les préférences: $savedRole');
  }

  // Vérifier le rôle d'un utilisateur par email
  static Future<Map<String, dynamic>> checkUserRole(String email) async {
    try {
      if (email.isEmpty) {
        return {'isAdmin': false};
      }

      // Utilisation de POST comme les autres méthodes
      final response = await http.post(
        Uri.parse('${baseUrl}/check_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'isAdmin': data['role'] == 'admin',
          'exists': data['exists'] ?? false,
        };
      }
      return {'isAdmin': false, 'exists': false};
    } catch (e) {
      print('Erreur lors de la vérification du rôle: $e');
      return {'isAdmin': false, 'exists': false};
    }
  }

  // Connexion avec retour de Map
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('=== DÉBUT DE LA CONNEXION ===');
      print('Email: $email');
      print('URL de base: $baseUrl');
      
      // Vérifier que SharedPreferences est initialisé
      if (_prefs == null) {
        print('Initialisation de SharedPreferences...');
        await init();
        print('SharedPreferences initialisé: ${_prefs != null}');
      }
      
      // Nettoyer les anciennes données
      print('Nettoyage des anciennes données...');
      await _prefs?.remove(tokenKey);
      await _prefs?.remove(userRoleKey);
      await _prefs?.remove(userEmailKey);
      
      // Désactiver le mode demo
      print('Désactivation du mode demo...');
      
      final url = '${baseUrl}/test_auth.php';
      print('URL de connexion: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La connexion a pris trop de temps');
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Réponse complète: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Données décodées: $data');
        
        if (data['success'] == true) {
          // Stocker le token
          final token = data['token'];
          print('Token reçu: $token');
          
          if (token == null) {
            print('ERREUR: Token manquant dans la réponse');
            throw Exception('Token manquant dans la réponse');
          }
          
          // Stockage des informations
          print('Stockage du token...');
          final tokenSaved = await _prefs?.setString(tokenKey, token);
          print('Token sauvegardé: $tokenSaved');
          
          print('Stockage du rôle...');
          final roleSaved = await _prefs?.setString(userRoleKey, data['user']['role']);
          print('Rôle sauvegardé: $roleSaved');
          
          print('Stockage de l\'email...');
          final emailSaved = await _prefs?.setString(userEmailKey, email);
          print('Email sauvegardé: $emailSaved');
          
          // Vérifier que le token a bien été stocké
          final storedToken = _prefs?.getString(tokenKey);
          print('Token stocké: $storedToken');
          
          if (storedToken == null) {
            print('ERREUR: Le token n\'a pas été stocké correctement');
            throw Exception('Le token n\'a pas été stocké correctement');
          }
          
          // Vérifier que le rôle a bien été stocké
          final storedRole = _prefs?.getString(userRoleKey);
          print('Rôle stocké: $storedRole');
          
          // Vérifier que l'email a bien été stocké
          final storedEmail = _prefs?.getString(userEmailKey);
          print('Email stocké: $storedEmail');
          
          print('=== FIN DE LA CONNEXION ===');
          return {
            'success': true,
            'isAdmin': data['user']['role'] == 'admin',
            'message': 'Connexion réussie',
            'user': data['user'],
          };
        } else {
          print('Échec de la connexion: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Email ou mot de passe incorrect',
          };
        }
      }
      
      print('Erreur de serveur: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    } catch (e) {
      print('Erreur de connexion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  // Inscription avec retour de Map
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'client',
  }) async {
    try {
      // Utilisation de POST comme demandé par le serveur
      final response = await http.post(
        Uri.parse('${baseUrl}/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      print('Statut de la réponse inscription: ${response.statusCode}');
      print('Réponse inscription: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Erreur inconnue',
        };
      }
      
      return {
        'success': false,
        'message': 'Erreur de serveur: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur d\'inscription: $e',
      };
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    print('=== DÉBUT DE LA DÉCONNEXION ===');
    print('Suppression du token...');
    await _prefs?.remove(tokenKey);
    print('Suppression du rôle...');
    await _prefs?.remove(userRoleKey);
    print('Suppression de l\'email...');
    await _prefs?.remove(userEmailKey);
    print('=== FIN DE LA DÉCONNEXION ===');
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = _prefs?.getString(tokenKey);
    print('Vérification de la connexion - Token: $token');
    return token != null;
  }

  // Récupérer le token
  static String? getToken() {
    final token = _prefs?.getString(tokenKey);
    print('Récupération du token: $token');
    print('SharedPreferences initialisé: ${_prefs != null}');
    return token;
  }

  // Vérifier si l'utilisateur est admin
  static Future<bool> isAdmin() async {
    final role = _prefs?.getString(userRoleKey);
    print('Role utilisateur actuel (isAdmin): $role');
    return role == 'admin';
  }

  // Récupérer l'email de l'utilisateur connecté
  static String? getCurrentUserEmail() {
    return _prefs?.getString(userEmailKey);
  }

  static String? getCurrentUserRole() {
    final roleFromStorage = _prefs?.getString(userRoleKey);
    
    // Correction robuste du rôle si nécessaire
    if (roleFromStorage != null) {
      final normalizedRole = roleFromStorage.toString().trim().toLowerCase();
      
      // Vérifier si c'est un admin (peu importe la casse ou les espaces)
      if (normalizedRole == 'admin' || normalizedRole == 'administrator' || 
          normalizedRole.contains('admin')) {
        print('Rôle admin confirmé (normalized): $normalizedRole');
        return 'admin';
      } else {
        print('Rôle client confirmé (normalized): $normalizedRole');
        return 'client';
      }
    }
    
    print('Aucun rôle trouvé dans les préférences');
    return null;
  }

  static String? _token;

  static String? get token => _token;

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<bool> isAuthenticated() async {
    if (_token == null) {
      await _loadToken();
    }
    return _token != null;
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      final email = prefs.getString(userEmailKey);

      if (token == null || email == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      print('URL de changement de mot de passe: ${baseUrl}/change_password.php');
      print('Email: $email');
      print('Token: $token');

      final response = await http.post(
        Uri.parse('${baseUrl}/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Réponse du serveur: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Erreur lors du changement de mot de passe',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Erreur lors du changement de mot de passe: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
} 