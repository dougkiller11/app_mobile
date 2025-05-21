import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:project_flutter/models/reservation_model.dart'; // Added import
import 'package:project_flutter/services/reservation_service.dart'; // Added import
import 'package:project_flutter/services/auth_service.dart'; // Added import
import 'package:shared_preferences/shared_preferences.dart'; // Added import
import 'package:flutter/services.dart'; // Pour TextInputFormatter

// NOUVEAU: Formatter pour le numéro de téléphone
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    var nonZeroIndex = 0;
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      nonZeroIndex++;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length && nonZeroIndex < 10) { // Limite à 10 chiffres pour les espaces
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    // Limiter la longueur totale (10 chiffres + 4 espaces = 14 caractères)
    if (string.length > 14) {
      string = string.substring(0, 14);
    }
    
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ReservationScreen extends StatefulWidget {
  static const routeName = '/reservation';

  const ReservationScreen({Key? key}) : super(key: key);

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTimeSlot; // Gardons cela, mais il stockera l'heure de début HH:MM
  bool _isLoading = false;
  String? _userEmail;
  String? _userName; // To potentially prefill from user data
  static const TimeOfDay _minReservationTime = TimeOfDay(hour: 11, minute: 30);
  int _numberOfPeople = 1; // Nouvel état pour le nombre de personnes
  final int _maxPeople = 10; // Limite max pour le compteur de personnes

  // Liste des heures de début HH:MM
  final List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    _timeSlots.clear();
    // Créneaux à partir de 11h30, toutes les heures
    // Vous pouvez ajuster l'heure de fin de service ici (par exemple, dernier créneau à 21h30)
    for (int h = 11; h <= 21; h++) { // Jusqu'à 21h inclus pour le créneau de 21h30
      if (h == 11) {
        _timeSlots.add("11:30");
      } else {
        // Pour les heures pleines après 11h30, on peut choisir de commencer à h:00 ou h:30
        // Votre demande: 12h-13h, 13h-14h => on prend h:00 comme début de créneau
        _timeSlots.add("${h.toString().padLeft(2, '0')}:00"); 
      }
      // Si vous voulez aussi des créneaux à la demi-heure pour les heures pleines:
      // if (h < 21) { // Pour éviter 21:30 suivi de 22:00 si 21:00 est le dernier
      // _timeSlots.add("${h.toString().padLeft(2, '0')}:30");
      // }
    }
    // Si vous voulez une logique stricte 11h30, puis 12h, 13h, 14h...
    // _timeSlots.add("11:30");
    // for (int h = 12; h <= 21; h++) { // Dernier créneau commence à 21h
    //   _timeSlots.add("${h.toString().padLeft(2, '0')}:00");
    // }
    // Assurez-vous qu'il n'y a pas de doublons et que c'est trié (normalement oui)
    // List<String> distinctSlots = _timeSlots.toSet().toList();
    // distinctSlots.sort();
    // _timeSlots.clear();
    // _timeSlots.addAll(distinctSlots);
  }

  Future<void> _loadUserData() async {
    await AuthService.init(); // Ensure SharedPreferences is initialized
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString(AuthService.userEmailKey);
      // Attempt to get user's full name if stored, otherwise keep name field blank
      // For now, let's assume full name might be part of user details if you store them
      // If not, user will fill it manually. Let's try to get it from SharedPreferences as an example.
      // You might store user's full name upon login if it's returned by your API.
      _userName = prefs.getString('user_full_name'); // Example key, adjust if you store it
      if (_userName != null) {
        _nameController.text = _userName!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date et une heure.'), backgroundColor: Colors.red),
        );
        return;
      }
      // La validation de l'heure minimale est implicitement gérée par les créneaux
      // si _selectedTimeSlot contient uniquement des heures valides.

      setState(() { _isLoading = true; });

      final reservation = Reservation(
        name: _nameController.text,
        phone: _phoneController.text,
        date: _selectedDate!,
        time: _selectedTimeSlot!, // Contient HH:MM de début
        numberOfPeople: _numberOfPeople,
        specialRequests: _specialRequestsController.text.isNotEmpty ? _specialRequestsController.text : null,
        userId: _userEmail,
      );

      final reservationService = ReservationService();
      final result = await reservationService.submitReservation(reservation);

      setState(() { _isLoading = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur inconnue'), backgroundColor: result['success'] ? Colors.green : Colors.red),
        );

        if (result['success']) {
          _formKey.currentState?.reset();
          _nameController.clear();
          _phoneController.clear();
          _specialRequestsController.clear();
          setState(() {
            _selectedDate = null;
            _selectedTimeSlot = null;
            _numberOfPeople = 1;
            if (_userName != null) { _nameController.text = _userName!; }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver une Table'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Numéro de téléphone', border: OutlineInputBorder(), hintText: 'XX XX XX XX XX'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // N'accepter que les chiffres
                    PhoneNumberFormatter(), // Notre formatter customisé
                    LengthLimitingTextInputFormatter(14), // 10 chiffres + 4 espaces
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone.';
                    }
                    final justDigits = value.replaceAll(' ', '');
                    if (justDigits.length != 10) {
                      return 'Le numéro doit contenir 10 chiffres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Aucune date choisie'
                            : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: const Text(
                        'Choisir une date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Heure de début', border: OutlineInputBorder()),
                  value: _selectedTimeSlot,
                  hint: const Text('Sélectionner une heure (dès 11h30)'),
                  isExpanded: true,
                  items: _timeSlots.map((String value) {
                    // On pourrait afficher "HH:MM - HH+1:MM" ici si on veut
                    // Pour l'instant, juste l'heure de début
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedTimeSlot = newValue; });
                  },
                  validator: (value) => value == null ? 'Veuillez choisir une heure.' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Nombre de personnes:', style: TextStyle(fontSize: 16)),
                    Row(
                      children: <Widget>[
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                          if (_numberOfPeople > 1) setState(() { _numberOfPeople--; });
                        }, splashRadius: 20),
                        Text('$_numberOfPeople', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                          if (_numberOfPeople < _maxPeople) setState(() { _numberOfPeople++; });
                        }, splashRadius: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specialRequestsController,
                  decoration: const InputDecoration(
                    labelText: 'Demandes spéciales (optionnel)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitReservation,
                        child: const Text('Réserver'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 