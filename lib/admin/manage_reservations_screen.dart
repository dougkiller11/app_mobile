import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_flutter/models/reservation_model.dart';
import 'package:project_flutter/services/reservation_service.dart';

class ManageReservationsScreen extends StatefulWidget {
  static const routeName = '/admin/manage-reservations';

  const ManageReservationsScreen({Key? key}) : super(key: key);

  @override
  _ManageReservationsScreenState createState() => _ManageReservationsScreenState();
}

class _ManageReservationsScreenState extends State<ManageReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reservations = await _reservationService.getReservationsForAdmin();
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur lors du chargement des réservations: ${e.toString()}";
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée': // French version
        return Colors.green.shade100;
      case 'pending':
      case 'en attente': // French version
        return Colors.orange.shade100;
      case 'declined':
      case 'refusée': // French version
      case 'cancelled':
      case 'annulée': // French version
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'declined':
        return 'Refusée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(String reservationId, String newStatus) async {
    // Afficher une boîte de dialogue de confirmation
    final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmer l\'action'),
            content: Text('Voulez-vous vraiment changer le statut à "${_translateStatus(newStatus)}" ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
              ),
              TextButton(
                child: Text('Confirmer', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        ) ?? false; // Retourne false si la boîte de dialogue est fermée sans sélection

    if (!confirm) {
      return;
    }

    setState(() {
      _isLoading = true; // Peut-être un indicateur de chargement plus localisé par carte ?
    });

    final result = await _reservationService.updateReservationStatus(reservationId, newStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur inconnue lors de la mise à jour.'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        // Mettre à jour l'état localement ou recharger toute la liste
        // Pour une meilleure UX, mettre à jour l'élément localement :
        setState(() {
          final index = _reservations.indexWhere((res) => res.id == reservationId);
          if (index != -1) {
            // Créer une nouvelle instance de Reservation avec le statut mis à jour
            // car les objets Reservation sont probablement immuables (final fields)
            // ou si la classe Reservation a un setter pour status, l'utiliser.
            // Assumons que nous devons recréer l'objet si les champs sont finaux.
            final oldRes = _reservations[index];
            _reservations[index] = Reservation(
              id: oldRes.id,
              name: oldRes.name,
              phone: oldRes.phone,
              date: oldRes.date,
              time: oldRes.time,
              numberOfPeople: oldRes.numberOfPeople,
              specialRequests: oldRes.specialRequests,
              userId: oldRes.userId,
              status: newStatus, // Le nouveau statut
            );
          }
          _isLoading = false;
        });
        // Alternativement, pour simplifier, recharger toutes les réservations :
        // _fetchReservations(); 
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> _buildActionButtons(Reservation reservation) {
    List<Widget> actions = [];
    String currentStatus = reservation.status.toLowerCase();

    if (currentStatus == 'pending' || currentStatus == 'en attente') {
      actions.add(TextButton(child: const Text('Confirmer'), onPressed: () => _updateStatus(reservation.id!, 'confirmed')));
      actions.add(TextButton(child: const Text('Refuser'), onPressed: () => _updateStatus(reservation.id!, 'declined')));
    }
    if (currentStatus == 'confirmed' || currentStatus == 'confirmée') {
      actions.add(TextButton(child: const Text('Terminer'), onPressed: () => _updateStatus(reservation.id!, 'completed')));
      actions.add(TextButton(child: const Text('Annuler (Client)'), onPressed: () => _updateStatus(reservation.id!, 'cancelled')));
    }
    // Pas d'actions pour 'declined', 'cancelled', 'completed' par défaut, mais vous pouvez en ajouter

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Réservations'),
        actions: [
          if (_isLoading) // Afficher l'indicateur de chargement dans l'appBar si _isLoading est vrai
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchReservations,
            )
        ],
      ),
      body: _isLoading && _reservations.isEmpty // Afficher le chargement initial seulement si la liste est vide
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : _reservations.isEmpty
                  ? const Center(child: Text('Aucune réservation à afficher.'))
                  : ListView.builder(
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _reservations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          color: _getStatusColor(reservation.status),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${reservation.name} - ${reservation.numberOfPeople} pers.',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text('Tel: ${reservation.phone}'),
                                Text('Date: ${DateFormat('dd/MM/yyyy').format(reservation.date)} à ${reservation.time}'),
                                if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text('Demandes: ${reservation.specialRequests}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ),
                                Text('Statut: ${_translateStatus(reservation.status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (reservation.userId != null)
                                  Text('Client: ${reservation.userId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0, // Espace horizontal entre les boutons
                                  children: _buildActionButtons(reservation),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 