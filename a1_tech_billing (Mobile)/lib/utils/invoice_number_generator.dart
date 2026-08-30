import '../services/database_service.dart';
import '../services/logger_service.dart';

class InvoiceNumberGenerator {
  static const String _invoicePrefix = 'INV';
  static const String _quotationPrefix = 'QT';
  static const String _poPrefix = 'PO';

  static final InvoiceNumberGenerator _instance =
      InvoiceNumberGenerator._internal();

  factory InvoiceNumberGenerator() => _instance;
  InvoiceNumberGenerator._internal();

  /// Generate next invoice number for given date
  /// Format: INV-YYYYMMDD-XXXXX (e.g., INV-20260701-00001)
  static Future<String> generateInvoiceNumber({DateTime? forDate}) async {
    forDate ??= DateTime.now();
    return _generateNumber(_invoicePrefix, forDate);
  }

  /// Generate next quotation number for given date
  /// Format: QT-YYYYMMDD-XXXXX (e.g., QT-20260701-00001)
  static Future<String> generateQuotationNumber({DateTime? forDate}) async {
    forDate ??= DateTime.now();
    return _generateNumber(_quotationPrefix, forDate);
  }

  /// Generate next purchase order number for given date
  /// Format: PO-YYYYMMDD-XXXXX (e.g., PO-20260701-00001)
  static Future<String> generatePurchaseOrderNumber({DateTime? forDate}) async {
    forDate ??= DateTime.now();
    return _generateNumber(_poPrefix, forDate);
  }

  static Future<String> _generateNumber(String prefix, DateTime date) async {
    try {
      final db = DatabaseService();
      final dateStr = _formatDate(date); // YYYY-MM-DD

      // Get current counter for this date
      final counter = await db.getInvoiceSequence(dateStr, prefix);
      final nextCounter = counter + 1;

      // Save updated counter
      await db.updateInvoiceSequence(dateStr, prefix, nextCounter);

      // Format: PREFIX-YYYYMMDD-XXXXX
      final formattedDate =
          date.toIso8601String().substring(0, 10).replaceAll('-', '');
      final formattedCounter = nextCounter.toString().padLeft(5, '0');

      return '$prefix-$formattedDate-$formattedCounter';
    } catch (e) {
      AppLogger.error('Failed to generate invoice number: $e',
          tag: 'InvoiceNumberGenerator');
      // Fallback to timestamp-based number
      return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse invoice date from invoice number (if possible)
  static DateTime? parseDate(String invoiceNumber) {
    try {
      // Format: PREFIX-YYYYMMDD-XXXXX
      final parts = invoiceNumber.split('-');
      if (parts.length == 3) {
        final dateStr = parts[1]; // YYYYMMDD
        if (dateStr.length == 8) {
          final year = int.parse(dateStr.substring(0, 4));
          final month = int.parse(dateStr.substring(4, 6));
          final day = int.parse(dateStr.substring(6, 8));
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      AppLogger.debug('Failed to parse date from invoice number: $e',
          tag: 'InvoiceNumberGenerator');
    }
    return null;
  }
}
