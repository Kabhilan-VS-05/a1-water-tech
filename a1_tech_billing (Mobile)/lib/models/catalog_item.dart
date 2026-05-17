import 'dart:convert';

class CatalogItem {
  final String id;
  final String type; // 'product' or 'service'
  final String name;
  final double price;
  final double gstPercent;
  final String? category;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final bool isSynced;
  final DateTime updatedAt;

  CatalogItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    this.gstPercent = 18.0,
    this.category,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.isSynced = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'price': price,
      'gst_percent': gstPercent,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: map['id'],
      type: map['type'],
      name: map['name'],
      price: map['price'].toDouble(),
      gstPercent: map['gst_percent']?.toDouble() ?? 18.0,
      category: map['category'],
      description: map['description'],
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1,
      isSynced: map['is_synced'] == 1,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => jsonEncode(toMap());

  CatalogItem copyWith({
    String? id,
    String? type,
    String? name,
    double? price,
    double? gstPercent,
    String? category,
    String? description,
    String? imageUrl,
    bool? isActive,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      price: price ?? this.price,
      gstPercent: gstPercent ?? this.gstPercent,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isProduct => type == 'product';
  bool get isService => type == 'service';

  // Calculate GST amount for this item
  double getGstAmount(int quantity) {
    return (price * quantity * gstPercent) / 100;
  }

  // Calculate total with GST for this item
  double getTotalWithGst(int quantity) {
    final baseAmount = price * quantity;
    final gstAmount = getGstAmount(quantity);
    return baseAmount + gstAmount;
  }

  // Display price with GST info
  String get displayPrice {
    final withGst = price + ((price * gstPercent) / 100);
    return 'Rs. ${price.toStringAsFixed(0)} (+${gstPercent.toStringAsFixed(0)}% GST = Rs. ${withGst.toStringAsFixed(0)})';
  }

  String get shortDisplayPrice => 'Rs. ${price.toStringAsFixed(0)}';
}
