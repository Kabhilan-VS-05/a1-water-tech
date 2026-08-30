import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db = DatabaseService();

  // ==================== BILLS EXPORT ====================

  Future<void> exportBillsToCsv() async {
    final bills = await _db.getBills();
    final buffer = StringBuffer();

    // CSV Header (Excel compatible)
    buffer.writeln(
      'Invoice No,Date,Customer Name,Phone,Customer GSTIN,Payment Mode,Subtotal (INR),GST Tax (INR),Other Charges (INR),Grand Total (INR),Status,Items Summary',
    );

    for (final bill in bills) {
      final itemsSummary = bill.items
          .map((i) => '${i.name} (${i.quantity}x @ ${i.price})')
          .join('; ');

      buffer.writeln([
        _csvEscape(bill.billNumber),
        _csvEscape(DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt)),
        _csvEscape(bill.customerName),
        _csvEscape(bill.customerPhone ?? ''),
        _csvEscape(bill.customerGst ?? ''),
        _csvEscape(bill.paymentMode),
        bill.subtotal.toStringAsFixed(2),
        bill.gstAmount.toStringAsFixed(2),
        '0.00',
        bill.total.toStringAsFixed(2),
        _csvEscape(bill.status),
        _csvEscape(itemsSummary),
      ].join(','));
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: utf8.encode(buffer.toString()),
      filename: 'A1_Bills_Export_$dateStr.csv',
    );
  }

  Future<void> exportBillsToJson() async {
    final bills = await _db.getBills();
    final jsonList = bills.map((b) => b.toMap()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: utf8.encode(jsonStr),
      filename: 'A1_Bills_Backup_$dateStr.json',
    );
  }

  // ==================== QUOTATIONS EXPORT ====================

  Future<void> exportQuotationsToCsv() async {
    final quotations = await _db.getQuotations();
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'Quotation No,Quotation Date,Valid Until,Customer Name,Phone,Customer GSTIN,Subtotal (INR),GST Tax (INR),Grand Total (INR),Status,Items Summary,Notes',
    );

    for (final q in quotations) {
      final itemsSummary = q.items
          .map((i) => '${i.name} (${i.quantity}x @ ${i.price})')
          .join('; ');

      buffer.writeln([
        _csvEscape(q.quotationNumber),
        _csvEscape(DateFormat('yyyy-MM-dd').format(q.createdAt)),
        _csvEscape(DateFormat('yyyy-MM-dd').format(q.validUntil)),
        _csvEscape(q.customerName),
        _csvEscape(q.customerPhone ?? ''),
        _csvEscape(q.customerGst ?? ''),
        q.subtotal.toStringAsFixed(2),
        q.gstAmount.toStringAsFixed(2),
        q.total.toStringAsFixed(2),
        _csvEscape(q.status),
        _csvEscape(itemsSummary),
        _csvEscape(q.notes ?? ''),
      ].join(','));
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: utf8.encode(buffer.toString()),
      filename: 'A1_Quotations_Export_$dateStr.csv',
    );
  }

  Future<void> exportQuotationsToJson() async {
    final quotations = await _db.getQuotations();
    final jsonList = quotations.map((q) => q.toMap()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: utf8.encode(jsonStr),
      filename: 'A1_Quotations_Backup_$dateStr.json',
    );
  }

  // ==================== CUSTOMERS EXPORT ====================

  Future<void> exportCustomersToCsv() async {
    final customers = await _db.getCustomers();
    final buffer = StringBuffer();

    buffer.writeln(
      'Customer ID,Name,Phone,Email,Address,Source,GSTIN,Created Date',
    );

    for (final c in customers) {
      buffer.writeln([
        _csvEscape(c.id),
        _csvEscape(c.name),
        _csvEscape(c.phone ?? ''),
        _csvEscape(c.email ?? ''),
        _csvEscape(c.address ?? ''),
        _csvEscape(c.source),
        '',
        _csvEscape(DateFormat('yyyy-MM-dd').format(c.createdAt)),
      ].join(','));
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: utf8.encode(buffer.toString()),
      filename: 'A1_Customers_Export_$dateStr.csv',
    );
  }

  // ==================== FULL DATABASE BACKUP ====================

  Future<void> exportFullDatabaseBackupJson() async {
    final bills = await _db.getBills();
    final quotations = await _db.getQuotations();
    final customers = await _db.getCustomers();
    final orders = await _db.getOrders();
    final bookings = await _db.getBookings();
    final products = await _db.getCatalogItems(type: 'product');
    final services = await _db.getCatalogItems(type: 'service');

    final backup = {
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '2.0.0',
      'company': 'A1 Water Tech',
      'stats': {
        'total_bills': bills.length,
        'total_quotations': quotations.length,
        'total_customers': customers.length,
        'total_orders': orders.length,
        'total_bookings': bookings.length,
        'total_catalog_items': products.length + services.length,
      },
      'data': {
        'bills': bills.map((b) => b.toMap()).toList(),
        'quotations': quotations.map((q) => q.toMap()).toList(),
        'customers': customers.map((c) => c.toMap()).toList(),
        'orders': orders.map((o) => o.toMap()).toList(),
        'bookings': bookings.map((b) => b.toMap()).toList(),
        'products': products.map((p) => p.toMap()).toList(),
        'services': services.map((s) => s.toMap()).toList(),
      },
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    await Printing.sharePdf(
      bytes: utf8.encode(jsonStr),
      filename: 'A1_Complete_Backup_$dateStr.json',
    );
  }

  String _csvEscape(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
