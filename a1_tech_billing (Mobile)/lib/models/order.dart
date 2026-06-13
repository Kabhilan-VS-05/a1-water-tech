import 'dart:convert';

class Order {
  final String id;
  final String? orderId; // Display ID from AWS (e.g., "A1-298963-687")
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double gstAmount;
  final double total;
  final String status; // pending, confirmed, completed, rejected
  final DateTime orderDate;
  final String? billId;
  final DateTime? syncedAt;

  Order({
    required this.id,
    this.orderId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
    this.status = 'pending',
    required this.orderDate,
    this.billId,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'items': jsonEncode(items.map((e) => e.toMap()).toList()),
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'total': total,
      'status': status,
      'order_date': orderDate.toIso8601String(),
      'bill_id': billId,
      'synced_at': syncedAt?.toIso8601String(),
      'is_synced': syncedAt != null ? 1 : 0,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    // Handle customer object from AWS
    final customerData = map['customer'];
    final addressData = map['address'];

    String customerName = 'Unknown Customer';
    String? customerPhone;
    String? customerAddress;

    if (customerData is Map) {
      customerName =
          customerData['fullName']?.toString() ??
          customerData['name']?.toString() ??
          'Unknown Customer';
      customerPhone = customerData['phone']?.toString();
      customerAddress = customerData['address']?.toString();
    }

    // Fallback to address data if customer data incomplete
    if (addressData is Map) {
      customerName = customerName == 'Unknown Customer'
          ? (addressData['name']?.toString() ?? 'Unknown Customer')
          : customerName;
      customerPhone ??= addressData['phone']?.toString();
      customerAddress ??= addressData['address']?.toString();
    }

    // Legacy field support
    customerName = map['customer_name']?.toString() ?? customerName;
    customerPhone ??= map['customer_phone']?.toString();
    customerAddress ??= map['customer_address']?.toString();

    // Handle items - can be List (AWS) or String (local SQLite)
    List<OrderItem> orderItems = [];
    final itemsData = map['items'];
    if (itemsData is List) {
      orderItems = itemsData.map((e) => OrderItem.fromMap(e)).toList();
    } else if (itemsData is String) {
      orderItems = (jsonDecode(itemsData) as List)
          .map((e) => OrderItem.fromMap(e))
          .toList();
    }

    return Order(
      id: map['id']?.toString() ?? map['docId']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? map['order_id']?.toString(),
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      items: orderItems,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0,
      gstAmount: double.tryParse(map['gst_amount']?.toString() ?? '0') ?? 0,
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0,
      status: (map['status']?.toString() ?? 'pending').toLowerCase(),
      orderDate:
          DateTime.tryParse(
            map['createdAt']?.toString() ?? map['order_date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      billId: map['billId']?.toString() ?? map['bill_id']?.toString(),
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'].toString())
          : null,
    );
  }

  Order copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? gstAmount,
    double? total,
    String? status,
    DateTime? orderDate,
    String? billId,
    DateTime? syncedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      billId: billId ?? this.billId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isBillable => isPending || isConfirmed;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Convert to JSON for sync queue
  String toJson() {
    return jsonEncode(toMap());
  }
}

class OrderItem {
  final String itemId;
  final String name;
  final String type;
  final double price;
  final int quantity;
  final double gstPercent;
  final String? hsn;
  final String? imageUrl;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.type,
    required this.price,
    this.quantity = 1,
    this.gstPercent = 18,
    this.hsn,
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
      'hsn': hsn ?? '',
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // Handle AWS format (qty, unitPrice) and local format (quantity, price)
    final quantity = map['qty'] ?? map['quantity'] ?? 1;
    final unitPrice = map['unitPrice'] ?? map['price'] ?? 0;
    final price = unitPrice is String
        ? double.tryParse(unitPrice) ?? 0
        : unitPrice.toDouble();

    return OrderItem(
      itemId:
          map['productId']?.toString() ??
          map['itemId']?.toString() ??
          map['id']?.toString() ??
          'unknown',
      name: map['name']?.toString() ?? 'Unknown Item',
      type: map['category']?.toString() ?? map['type']?.toString() ?? 'product',
      price: price,
      quantity: quantity is String ? int.tryParse(quantity) ?? 1 : quantity,
      gstPercent: (map['gstPercent'] ?? 18).toDouble(),
      hsn: map['hsn']?.toString() ?? '',
      imageUrl: map['image']?.toString() ?? map['imageUrl']?.toString(),
    );
  }

  double get total => price * quantity;
  double get gstAmount => (total * gstPercent) / 100;
  double get totalWithGst => total + gstAmount;
}
