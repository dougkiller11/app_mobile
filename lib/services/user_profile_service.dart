import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String name;
  String email;
  String phone;
  String address;
  String? profileImagePath;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.profileImagePath,
  });

  // Conversion de UserProfile en Map pour stockage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImagePath': profileImagePath,
    };
  }

  // Création d'un UserProfile à partir d'une Map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      profileImagePath: json['profileImagePath'],
    );
  }

  // Création d'un profil par défaut
  factory UserProfile.defaultProfile(String email) {
    return UserProfile(
      name: 'Utilisateur',
      email: email,
      phone: '',
      address: '',
      profileImagePath: null,
    );
  }
}

class UserProfileService {
  static const String _profileKey = 'user_profile_data';

  // Sauvegarde du profil utilisateur
  static Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(profile.toJson());
      return await prefs.setString('${_profileKey}_${profile.email}', userJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde du profil: $e');
      return false;
    }
  }

  // Récupération du profil utilisateur
  static Future<UserProfile?> getUserProfile(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('${_profileKey}_$email');
      
      if (userJson != null) {
        return UserProfile.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Récupération du profil utilisateur ou création d'un profil par défaut
  static Future<UserProfile> getUserProfileOrDefault(String email) async {
    final profile = await getUserProfile(email);
    return profile ?? UserProfile.defaultProfile(email);
  }

  // Mise à jour partielle du profil (ne modifie que les champs fournis)
  static Future<bool> updateUserProfile({
    required String email,
    String? name,
    String? phone,
    String? address,
    String? profileImagePath,
  }) async {
    final profile = await getUserProfileOrDefault(email);
    
    if (name != null) profile.name = name;
    if (phone != null) profile.phone = phone;
    if (address != null) profile.address = address;
    if (profileImagePath != null) profile.profileImagePath = profileImagePath;
    
    return saveUserProfile(profile);
  }
} 