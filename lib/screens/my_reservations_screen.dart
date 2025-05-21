import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_flutter/models/reservation_model.dart';
import 'package:project_flutter/services/reservation_service.dart';
import 'package:project_flutter/services/auth_service.dart'; // Pour récupérer l'user ID (email)
import 'package:shared_preferences/shared_preferences.dart';

class MyReservationsScreen extends StatefulWidget {
  static const routeName = '/my-reservations';

  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  _MyReservationsScreenState createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  List<Reservation> _userReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndFetchReservations();
  }

  Future<void> _loadCurrentUserAndFetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Assurez-vous que AuthService est initialisé si ce n'est pas fait dans main.dart
      // await AuthService.init(); 
      final prefs = await SharedPreferences.getInstance();
      _currentUserEmail = prefs.getString(AuthService.userEmailKey);

      if (_currentUserEmail == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Utilisateur non connecté. Veuillez vous connecter pour voir vos réservations.";
        });
        return;
      }
      
      final reservations = await _reservationService.getUserReservations(_currentUserEmail!);
      setState(() {
        _userReservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur lors du chargement de vos réservations: ${e.toString()}";
      });
    }
  }

  Color _getStatusColor(String status) {
    // Vous pouvez réutiliser la même logique de couleur que dans ManageReservationsScreen
    // ou l'adapter si les couleurs doivent être différentes pour le client.
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée': 
        return Colors.green.shade100;
      case 'pending':
      case 'en attente': 
        return Colors.orange.shade100;
      case 'declined':
      case 'refusée': 
      case 'cancelled':
      case 'annulée': 
        return Colors.red.shade100;
      case 'completed':
      case 'terminée':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _translateStatus(String status) {
    // Idem pour la traduction
    switch (status.toLowerCase()) {
      case 'pending': return 'En attente de confirmation';
      case 'confirmed': return 'Confirmée';
      case 'declined': return 'Refusée par le restaurant';
      case 'cancelled': return 'Annulée'; // Peut être 'Annulée par vous' ou 'Annulée par le restaurant' si plus de détails
      case 'completed': return 'Terminée';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentUserAndFetchReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : _userReservations.isEmpty
                  ? Center(
                      child: Text(
                        _currentUserEmail == null 
                          ? "Veuillez vous connecter pour voir vos réservations."
                          : "Vous n\'avez aucune réservation pour le moment.",
                        textAlign: TextAlign.center,
                      )
                    )
                  : ListView.builder(
                      itemCount: _userReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _userReservations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          color: _getStatusColor(reservation.status),
                          child: ListTile(
                            title: Text(
                              'Réservation pour ${reservation.numberOfPeople} pers.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(reservation.date)} à ${reservation.time}'),
                                Text('Statut: ${_translateStatus(reservation.status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text('Vos demandes: ${reservation.specialRequests}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ),
                                Text('Faite le: ${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.parse(reservation.toJson()['created_at'] ?? DateTime.now().toIso8601String()))}'), // Assumes created_at is available
                                // TODO: Ajouter des boutons Modifier/Annuler ici (prochaine étape)
                              ],
                            ),
                            // Ajuster isThreeLine en fonction du contenu affiché
                            isThreeLine: true, 
                          ),
                        );
                      },
                    ),
    );
  }
} 