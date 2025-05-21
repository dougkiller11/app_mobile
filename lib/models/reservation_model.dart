class Reservation {
  final String? id;
  final String name;
  final String phone;
  final DateTime date;
  final String time; // Using String for time for now, can be refined with TimeOfDay
  final int numberOfPeople;
  final String? specialRequests;
  String status; // e.g., 'pending', 'confirmed', 'declined'
  final String? userId;

  Reservation({
    this.id,
    required this.name,
    required this.phone,
    required this.date,
    required this.time,
    required this.numberOfPeople,
    this.specialRequests,
    this.status = 'pending',
    this.userId,
  });

  // Factory constructor to create a Reservation from JSON (useful for API calls)
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      numberOfPeople: json['numberOfPeople'] is String ? int.parse(json['numberOfPeople'] as String) : json['numberOfPeople'] as int,
      specialRequests: json['specialRequests'] as String?,
      status: json['status'] as String? ?? 'pending',
      userId: json['userId'] as String?,
    );
  }

  // Method to convert a Reservation to JSON (useful for API calls)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'time': time,
      'numberOfPeople': numberOfPeople,
      'specialRequests': specialRequests,
      'status': status,
      'userId': userId,
    };
  }
} 