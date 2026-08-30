import 'dart:convert';

class Address {
  final String id;
  final String? customerId;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String type; // billing, shipping, correspondence
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    this.customerId,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    this.type = 'billing',
    this.isDefault = false,
    required this.createdAt,
  });

  String get fullAddress => '$street, $city, $state - $zipCode';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'phone': phone,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      customerId: map['customer_id'] as String?,
      name: map['name'] as String,
      street: map['street'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zipCode: map['zip_code'] as String,
      phone: map['phone'] as String,
      type: map['type'] as String? ?? 'billing',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Address.fromJson(String json) {
    return Address.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  String toJson() => jsonEncode(toMap());

  Address copyWith({
    String? id,
    String? customerId,
    String? name,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
