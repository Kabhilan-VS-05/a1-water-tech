import 'dart:convert';

class Booking {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String? email;
  final String? city;
  final String? address;
  final String serviceType;
  final DateTime? date;
  final String? slot;
  final String status; // pending, confirmed, completed, rejected
  final DateTime createdAt;
  final DateTime? confirmedAt;

  Booking({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.city,
    this.address,
    required this.serviceType,
    this.date,
    this.slot,
    this.status = 'pending',
    required this.createdAt,
    this.confirmedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'city': city,
      'address': address,
      'service_type': serviceType,
      'date': date?.toIso8601String(),
      'slot': slot,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'is_synced': 1,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id']?.toString() ?? map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString(),
      name: map['name']?.toString() ?? 'Unknown Customer',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      city: map['city']?.toString(),
      address: map['address']?.toString() ?? map['addressSnapshot']?['address']?.toString(),
      serviceType: map['serviceType']?.toString() ?? map['service_type']?.toString() ?? map['serviceName']?.toString() ?? 'General Service',
      date: DateTime.tryParse(map['date']?.toString() ?? ''),
      slot: map['slot']?.toString(),
      status: (map['status']?.toString() ?? 'pending').toLowerCase(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? map['created_at']?.toString() ?? '') ?? DateTime.now(),
      confirmedAt: DateTime.tryParse(map['confirmedAt']?.toString() ?? map['confirmed_at']?.toString() ?? ''),
    );
  }

  // Convert to JSON for sync queue if needed
  String toJson() {
    return jsonEncode(toMap());
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
}
