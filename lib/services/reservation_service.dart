import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_flutter/models/reservation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReservationService {
  // TODO: Mettez ici l'URL de base de votre API
  // static const String _baseUrl = 'http://votre_domaine_ou_ip/restaurant_api/'; // ANCIENNE LIGNE
  // REMPLACEZ PAR VOTRE URL RÉELLE CI-DESSOUS. EXEMPLE POUR SERVEUR LOCAL ET ÉMULATEUR ANDROID:
  static const String _baseUrl = 'http://10.0.2.2/restaurant_api/'; 
  // OU SI VOTRE DOSSIER API EST DANS UN SOUS-DOSSIER DE HTDOCS, par ex. htdocs/mon_projet_php/restaurant_api:
  // static const String _baseUrl = 'http://10.0.2.2/mon_projet_php/restaurant_api/'; 

  Future<Map<String, dynamic>> submitReservation(Reservation reservation) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // Assurez-vous que l'userId est inclus s'il est disponible
    // L'objet reservation contient déjà userId s'il a été défini lors de sa création.

    final url = Uri.parse('${_baseUrl}create_reservation.php');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token', // Envoyez le token si disponible
        },
        body: json.encode(reservation.toJson()),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == 'success') {
          return {'success': true, 'message': responseData['message'] ?? 'Réservation soumise avec succès'};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Erreur lors de la soumission de la réservation.'};
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('Error in submitReservation: $error');
      return {'success': false, 'message': 'Une erreur s\'est produite: ${error.toString()}'};
    }
  }
  
  Future<List<Reservation>> getReservationsForAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Admin token

    final url = Uri.parse('${_baseUrl}get_reservations.php');

    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final List<dynamic> reservationsData = responseData['data'];
          return reservationsData.map((data) => Reservation.fromJson(data as Map<String, dynamic>)).toList();
        } else {
          // Gérer le cas où 'data' est null ou le statut n'est pas success
          print('Error from server (getReservationsForAdmin): ${responseData['message']}');
          return []; // Retourner une liste vide en cas d'erreur ou pas de données
        }
      } else {
        print('Server error (getReservationsForAdmin): ${response.statusCode} - ${response.body}');
        return []; // Retourner une liste vide en cas d'erreur serveur
      }
    } catch (error) {
      print('Error in getReservationsForAdmin: $error');
      return []; // Retourner une liste vide en cas d'exception
    }
  }

  Future<Map<String, dynamic>> updateReservationStatus(String reservationId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Admin token

    final url = Uri.parse('${_baseUrl}update_reservation_status.php');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reservation_id': reservationId,
          'new_status': newStatus,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          return {'success': true, 'message': responseData['message'] ?? 'Statut mis à jour.'};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Erreur lors de la mise à jour.'};
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('Error in updateReservationStatus: $error');
      return {'success': false, 'message': 'Une erreur s\'est produite: ${error.toString()}'};
    }
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // User token

    final url = Uri.parse('${_baseUrl}get_user_reservations.php');

    try {
      final response = await http.post( // Ou http.get si vous changez le PHP pour prendre userId en query param
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final List<dynamic> reservationsData = responseData['data'];
          return reservationsData.map((data) => Reservation.fromJson(data as Map<String, dynamic>)).toList();
        } else {
          print('Error from server (getUserReservations): ${responseData['message']}');
          return []; 
        }
      } else {
        print('Server error (getUserReservations): ${response.statusCode} - ${response.body}');
        return []; 
      }
    } catch (error) {
      print('Error in getUserReservations: $error');
      return []; 
    }
  }

  // Vous pourrez ajouter ici d'autres méthodes (getReservationsForUser, getAllReservationsForAdmin, etc.)
} 