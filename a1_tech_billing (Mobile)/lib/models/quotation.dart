import 'dart:convert';

class Quotation {
  final String id;
  final String quotationNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGst;
  final String? customerEmail;
  final List<QuotationItem> items;
  final double subtotal;
  final double gstAmount;
  final double total;
  final String status; // draft, sent, accepted, rejected, converted
  final DateTime validUntil;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? otherChargeLabel;
  final double? otherChargeAmount;
  final bool isOtherChargeTaxable;
  final double? otherChargeGstPercent;
  final String? terms;
  final bool isRoundedOff;

  Quotation({
    required this.id,
    required this.quotationNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerGst,
    this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
    this.status = 'draft',
    required this.validUntil,
    this.notes,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.otherChargeLabel,
    this.otherChargeAmount,
    this.isOtherChargeTaxable = false,
    this.otherChargeGstPercent,
    this.terms,
    this.isRoundedOff = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_number': quotationNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'customer_gst': customerGst,
      'customer_email': customerEmail,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'total': total,
      'status': status,
      'valid_until': validUntil.toIso8601String(),
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'other_charge_label': otherChargeLabel,
      'other_charge_amount': otherChargeAmount,
      'is_other_charge_taxable': isOtherChargeTaxable ? 1 : 0,
      'other_charge_gst_percent': otherChargeGstPercent,
      'terms': terms,
      'is_rounded_off': isRoundedOff ? 1 : 0,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    final itemsList = jsonDecode(map['items'] as String? ?? '[]') as List;
    return Quotation(
      id: map['id'] as String,
      quotationNumber: map['quotation_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      customerGst: map['customer_gst'] as String?,
      customerEmail: map['customer_email'] as String?,
      items: itemsList
          .map((item) => QuotationItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      gstAmount: (map['gst_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'draft',
      validUntil: DateTime.parse(map['valid_until'] as String),
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      otherChargeLabel: map['other_charge_label'] as String?,
      otherChargeAmount: map['other_charge_amount'] != null ? (map['other_charge_amount'] as num).toDouble() : null,
      isOtherChargeTaxable: (map['is_other_charge_taxable'] as int? ?? 0) == 1,
      otherChargeGstPercent: map['other_charge_gst_percent'] != null ? (map['other_charge_gst_percent'] as num).toDouble() : null,
      terms: map['terms'] as String?,
      isRoundedOff: (map['is_rounded_off'] as int? ?? 0) == 1,
    );
  }

  Quotation copyWith({
    String? id,
    String? quotationNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerGst,
    String? customerEmail,
    List<QuotationItem>? items,
    double? subtotal,
    double? gstAmount,
    double? total,
    String? status,
    DateTime? validUntil,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? otherChargeLabel,
    double? otherChargeAmount,
    bool? isOtherChargeTaxable,
    double? otherChargeGstPercent,
    String? terms,
    bool? isRoundedOff,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGst: customerGst ?? this.customerGst,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherChargeLabel: otherChargeLabel ?? this.otherChargeLabel,
      otherChargeAmount: otherChargeAmount ?? this.otherChargeAmount,
      isOtherChargeTaxable: isOtherChargeTaxable ?? this.isOtherChargeTaxable,
      otherChargeGstPercent: otherChargeGstPercent ?? this.otherChargeGstPercent,
      terms: terms ?? this.terms,
      isRoundedOff: isRoundedOff ?? this.isRoundedOff,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isConverted => status == 'converted';
  bool get isExpired => DateTime.now().isAfter(validUntil);
}

class QuotationItem {
  final String itemId;
  final String name;
  final String type; // product or service
  final String? hsn;
  final double price;
  final int quantity;
  final double gstPercent;
  final double gstAmount;
  final double total;
  final String? imageUrl;

  QuotationItem({
    required this.itemId,
    required this.name,
    required this.type,
    this.hsn,
    required this.price,
    required this.quantity,
    required this.gstPercent,
    required this.gstAmount,
    required this.total,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'name': name,
      'type': type,
      'hsn': hsn,
      'price': price,
      'quantity': quantity,
      'gst_percent': gstPercent,
      'gst_amount': gstAmount,
      'total': total,
      'image_url': imageUrl,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      itemId: map['item_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      hsn: map['hsn'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      gstPercent: (map['gst_percent'] as num).toDouble(),
      gstAmount: (map['gst_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
    );
  }

  QuotationItem copyWith({
    String? itemId,
    String? name,
    String? type,
    String? hsn,
    double? price,
    int? quantity,
    double? gstPercent,
    double? gstAmount,
    double? total,
    String? imageUrl,
  }) {
    return QuotationItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      type: type ?? this.type,
      hsn: hsn ?? this.hsn,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      gstPercent: gstPercent ?? this.gstPercent,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
