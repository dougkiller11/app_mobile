class BankCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final bool isDefault;

  BankCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    this.isDefault = false,
  });

  factory BankCard.fromJson(Map<String, dynamic> json) {
    return BankCard(
      id: json['id'] ?? '',
      cardNumber: json['card_number'] ?? '',
      cardHolder: json['card_holder'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      cvv: json['cvv'] ?? '',
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_number': cardNumber,
      'card_holder': cardHolder,
      'expiry_date': expiryDate,
      'cvv': cvv,
      'is_default': isDefault,
    };
  }

  // Masquer tous les chiffres sauf les 4 derniers
  String get maskedCardNumber {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Masquer le CVV
  String get maskedCvv => '***';
} 