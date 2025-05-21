import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class SimpleUserService {
  static String get baseUrl => AuthService.baseUrl;

  // Récupérer la liste des utilisateurs
  static Future<Map<String, List<User>>> getUsersList() async {
    try {
      print('=== DÉBUT DE LA RÉCUPÉRATION DES UTILISATEURS ===');
      final url = '${baseUrl}/list_users.php';
      print('Appel de l\'URL: $url');
      
      final response = await http.get(Uri.parse(url));

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final admins = (data['admins'] as List)
              .map((json) => User.fromJson(json))
              .toList();
          
          final clients = (data['clients'] as List)
              .map((json) => User.fromJson(json))
              .toList();

          return {
            'admins': admins,
            'clients': clients,
          };
        }
        throw Exception('Format de réponse invalide');
      }
      throw Exception('Erreur lors de la récupération des utilisateurs: ${response.statusCode}');
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      throw Exception('Erreur: $e');
    } finally {
      print('=== FIN DE LA RÉCUPÉRATION DES UTILISATEURS ===');
    }
  }
} 