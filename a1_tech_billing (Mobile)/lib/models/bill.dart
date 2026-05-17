import 'dart:convert';

class Bill {
  final String id;
  final String billNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<BillItem> items;
  final double subtotal;
  final double gstAmount;
  final double total;
  final String paymentMode; // cash, online, pending
  final String status; // draft, confirmed, paid
  final String? orderId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    required this.id,
    required this.billNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
    this.paymentMode = 'pending',
    this.status = 'draft',
    this.orderId,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'items': jsonEncode(items.map((e) => e.toMap()).toList()),
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'total': total,
      'payment_mode': paymentMode,
      'status': status,
      'order_id': orderId,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'];
    List<BillItem> parsedItems = [];
    if (itemsData != null) {
      if (itemsData is String) {
        parsedItems = (jsonDecode(itemsData) as List)
            .map((e) => BillItem.fromMap(e))
            .toList();
      } else if (itemsData is List) {
        parsedItems = itemsData.map((e) => BillItem.fromMap(e)).toList();
      }
    }

    return Bill(
      id: map['id']?.toString() ?? '',
      billNumber: (map['bill_number'] ?? map['billNumber'])?.toString() ?? '',
      customerId: map['customer_id'] ?? map['customerId'],
      customerName: map['customer_name'] ?? map['customerName'] ?? 'Unknown',
      customerPhone: map['customer_phone'] ?? map['customerPhone'],
      customerAddress: map['customer_address'] ?? map['customerAddress'],
      items: parsedItems,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0,
      gstAmount: double.tryParse((map['gst_amount'] ?? map['gstAmount'])?.toString() ?? '0') ?? 0,
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0,
      paymentMode: map['payment_mode'] ?? map['paymentMode'] ?? 'pending',
      status: map['status'] ?? 'draft',
      orderId: map['order_id'] ?? map['orderId'],
      isSynced: map['is_synced'] == 1 || map['is_synced'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  Bill copyWith({
    String? id,
    String? billNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    List<BillItem>? items,
    double? subtotal,
    double? gstAmount,
    double? total,
    String? paymentMode,
    String? status,
    String? orderId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BillItem {
  final String itemId;
  final String name;
  final String type; // product or service
  final double price;
  final int quantity;
  final double gstPercent;
  final double gstAmount;
  final double total;
  final String? imageUrl;

  BillItem({
    required this.itemId,
    required this.name,
    required this.type,
    required this.price,
    this.quantity = 1,
    this.gstPercent = 18,
    required this.gstAmount,
    required this.total,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'type': type,
      'price': price,
      'quantity': quantity,
      'gstPercent': gstPercent,
      'gstAmount': gstAmount,
      'total': total,
      'imageUrl': imageUrl,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      itemId: map['itemId'],
      name: map['name'],
      type: map['type'],
      price: map['price'].toDouble(),
      quantity: map['quantity'] ?? 1,
      gstPercent: map['gstPercent']?.toDouble() ?? 18,
      gstAmount: map['gstAmount'].toDouble(),
      total: map['total'].toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  BillItem copyWith({
    String? itemId,
    String? name,
    String? type,
    double? price,
    int? quantity,
    double? gstPercent,
    double? gstAmount,
    double? total,
    String? imageUrl,
  }) {
    return BillItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      gstPercent: gstPercent ?? this.gstPercent,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
