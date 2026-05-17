import 'dart:convert';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final String source; // 'website' or 'manual'
  final int totalVisits;
  final double totalSpent;
  final bool isSynced;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.source = 'manual',
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.isSynced = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'source': source,
      'total_visits': totalVisits,
      'total_spent': totalSpent,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      source: map['source'] ?? 'manual',
      totalVisits: map['total_visits'] ?? 0,
      totalSpent: map['total_spent']?.toDouble() ?? 0.0,
      isSynced: map['is_synced'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => jsonEncode(toMap());

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? email,
    String? source,
    int? totalVisits,
    double? totalSpent,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      source: source ?? this.source,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => name;

  String get displayPhone => phone ?? 'No phone';

  String get displayAddress => address ?? 'No address';
}
