import 'dart:convert';
import 'bill.dart';
import 'address.dart';

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final Address billingAddress;
  final Address shippingAddress;
  final List<BillItem> items;
  final double subtotal;
  final double gstAmount;
  final double total;
  final DateTime? deliveryDate;
  final String? paymentTerms;
  final String? notes;
  final String status; // draft, sent, accepted, rejected, converted
  final String? quotationId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.billingAddress,
    required this.shippingAddress,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
    this.deliveryDate,
    this.paymentTerms,
    this.notes,
    this.status = 'draft',
    this.quotationId,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_number': poNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'billing_address': billingAddress.toJson(),
      'shipping_address': shippingAddress.toJson(),
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'total': total,
      'delivery_date': deliveryDate?.toIso8601String(),
      'payment_terms': paymentTerms,
      'notes': notes,
      'status': status,
      'quotation_id': quotationId,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    final itemsList = jsonDecode(map['items'] as String? ?? '[]') as List;
    return PurchaseOrder(
      id: map['id'] as String,
      poNumber: map['po_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      billingAddress: Address.fromJson(map['billing_address'] as String),
      shippingAddress: Address.fromJson(map['shipping_address'] as String),
      items: itemsList
          .map((item) => BillItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      gstAmount: (map['gst_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      deliveryDate: map['delivery_date'] != null
          ? DateTime.parse(map['delivery_date'] as String)
          : null,
      paymentTerms: map['payment_terms'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'draft',
      quotationId: map['quotation_id'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  PurchaseOrder copyWith({
    String? id,
    String? poNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    Address? billingAddress,
    Address? shippingAddress,
    List<BillItem>? items,
    double? subtotal,
    double? gstAmount,
    double? total,
    DateTime? deliveryDate,
    String? paymentTerms,
    String? notes,
    String? status,
    String? quotationId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      quotationId: quotationId ?? this.quotationId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isConverted => status == 'converted';
}
