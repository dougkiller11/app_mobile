import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  static String get baseUrl => AuthService.baseUrl;

  // Récupérer tous les utilisateurs
  static Future<List<User>> getAllUsers() async {
    try {
      print('=== DÉBUT DE LA RÉCUPÉRATION DES UTILISATEURS ===');
      print('URL de base: $baseUrl');
      final token = AuthService.getToken();
      print('Token: $token');
      print('Rôle actuel: ${await AuthService.isAdmin()}');
      
      if (token == null) {
        throw Exception('Token non disponible');
      }

      // Continuer avec get_users.php
      final url = '${baseUrl}/get_users.php';
      print('Appel de l\'URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['users'] != null) {
          return (data['users'] as List).map((json) => User.fromJson(json)).toList();
        }
        throw Exception('Format de réponse invalide');
      } else if (response.statusCode == 403) {
        throw Exception('Accès non autorisé. Vous devez être administrateur.');
      }
      throw Exception('Erreur lors de la récupération des utilisateurs: ${response.statusCode}');
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      throw Exception('Erreur: $e');
    } finally {
      print('=== FIN DE LA RÉCUPÉRATION DES UTILISATEURS ===');
    }
  }

  // Mettre à jour un utilisateur
  static Future<Map<String, dynamic>> updateUser(User user) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/update_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Utilisateur mis à jour avec succès',
        };
      }
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  // Supprimer un utilisateur
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/delete_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'id': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Utilisateur supprimé avec succès',
        };
      }
      throw Exception('Erreur lors de la suppression de l\'utilisateur');
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }
} 