import '../../utils/image_helper.dart';
import '../../utils/invoice_number_generator.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../services/pdf_service.dart';
import '../../services/logger_service.dart';
import '../../theme/app_theme.dart';

class AutoBillingScreen extends StatefulWidget {
  const AutoBillingScreen({super.key});

  @override
  State<AutoBillingScreen> createState() => _AutoBillingScreenState();
}

class _AutoBillingScreenState extends State<AutoBillingScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  Order? _order;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _orderLoaded = false; // Guard flag to prevent re-loading

  @override
  void initState() {
    super.initState();
    // Schedule after first frame so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_orderLoaded) _loadOrder();
    });
  }

  Future<void> _loadOrder() async {
    _orderLoaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Order) {
      setState(() {
        _order = args;
        _isLoading = false;
      });
    } else {
      // If no order passed, go back
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _generateBill(String paymentStatus, String paymentMode) async {
    if (_order == null) return;

    setState(() => _isGenerating = true);

    final now = DateTime.now();
    final billNumber =
        await InvoiceNumberGenerator.generateInvoiceNumber(forDate: now);

    // Convert order items to bill items with the latest catalog images and HSN codes
    final List<BillItem> billItems = [];
    for (var orderItem in _order!.items) {
      String? latestImageUrl = orderItem.imageUrl;
      String? hsn = orderItem.hsn;
      try {
        final catalogItem = await _db.getCatalogItemById(orderItem.itemId);
        if (catalogItem != null) {
          if (catalogItem.imageUrl != null && catalogItem.imageUrl!.isNotEmpty) {
            latestImageUrl = catalogItem.imageUrl;
          }
          if (catalogItem.hsn != null && catalogItem.hsn!.isNotEmpty) {
            hsn = catalogItem.hsn;
          }
        }
      } catch (e) {
        debugPrint('Error getting catalog item details during billing: $e');
      }

      billItems.add(BillItem(
        itemId: orderItem.itemId,
        name: orderItem.name,
        type: orderItem.type,
        hsn: hsn,
        price: orderItem.price,
        quantity: orderItem.quantity,
        gstPercent: orderItem.gstPercent,
        gstAmount: orderItem.gstAmount,
        total: orderItem.totalWithGst,
        imageUrl: latestImageUrl,
      ));
    }

    final bill = Bill(
      id: billNumber,
      billNumber: billNumber,
      customerName: _order!.customerName,
      customerPhone: _order!.customerPhone,
      customerAddress: _order!.customerAddress,
      items: billItems,
      subtotal: _order!.subtotal,
      gstAmount: _order!.gstAmount,
      total: _order!.total,
      paymentMode: paymentMode,
      status: paymentStatus,
      orderId: _order!.id,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertBill(bill);

    // Update order status
    await _db.updateOrderStatus(_order!.id, 'completed', billId: bill.id);

    // Auto-sync to AWS if online
    await _sync.syncOnSave();

    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill #$billNumber generated successfully!')),
      );

      // Generate and show PDF
      try {
        final isDigital = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Signature Option'),
            content: const Text('Choose how you want to sign the invoice:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), // Manual
                child: const Text('MANUAL SIGN'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), // Digital
                child: const Text('DIGITAL SIGN'),
              ),
            ],
          ),
        );
        if (isDigital != null) {
          final pdfFile = await PdfService.generateInvoice(bill, isDigitalSignature: isDigital);
          await Printing.layoutPdf(
            name: 'Invoice_$billNumber',
            onLayout: (format) => pdfFile,
          );
        }
      } catch (e) {
        AppLogger.error('PDF generation error: $e', tag: 'AutoBilling');
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showConfirmationAndGenerate() async {
    String paymentStatus = 'paid';
    String paymentMode = 'cash';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.payment_rounded, color: Color(0xFF4F46E5)),
                const SizedBox(width: 10),
                const Text('Payment Settlement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose payment status and mode before generating the bill:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 20),
                
                // Payment Status Toggle
                const Text('Payment Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paymentStatus == 'paid' ? Colors.green : Colors.transparent,
                          foregroundColor: paymentStatus == 'paid' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          elevation: paymentStatus == 'paid' ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: paymentStatus == 'paid' ? Colors.green : Colors.grey.shade400),
                          ),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            paymentStatus = 'paid';
                          });
                        },
                        child: const Text('PAID'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paymentStatus == 'pending' ? Colors.amber.shade700 : Colors.transparent,
                          foregroundColor: paymentStatus == 'pending' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          elevation: paymentStatus == 'pending' ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: paymentStatus == 'pending' ? Colors.amber.shade700 : Colors.grey.shade400),
                          ),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            paymentStatus = 'pending';
                            paymentMode = 'pending';
                          });
                        },
                        child: const Text('PENDING'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Payment Mode Selector (Enabled only if PAID is selected)
                if (paymentStatus == 'paid') ...[
                  const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paymentMode == 'pending' ? 'cash' : paymentMode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                      ),
                    ),
                    items: ['cash', 'upi', 'card', 'bank_transfer'].map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(mode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          paymentMode = v;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generateBill(paymentStatus, paymentMode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('GENERATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_order == null) {
      return const Scaffold(body: Center(child: Text('No order data')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill from Order'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info Card
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order #${_order!.orderId ?? (_order!.id.length > 8 ? _order!.id.substring(0, 8).toUpperCase() : _order!.id.toUpperCase())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person, _order!.customerName),
                          if (_order!.customerPhone != null)
                            _buildInfoRow(Icons.phone, _order!.customerPhone!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Items List
                  Text(
                    'Order Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._order!.items.map((item) => _OrderItemCard(item: item)),
                  const SizedBox(height: 20),

                  // Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', _order!.subtotal),
                          _buildSummaryRow(
                            'GST (${_order!.gstAmount > 0 ? "18%" : "0%"})',
                            _order!.gstAmount,
                          ),
                          const Divider(),
                          _buildSummaryRow(
                            'Total',
                            _order!.total,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Generate Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _showConfirmationAndGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'GENERATE BILL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: isBold
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4F46E5),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatefulWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  State<_OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<_OrderItemCard> {
  final DatabaseService _db = DatabaseService();
  String? _latestImageUrl;

  @override
  void initState() {
    super.initState();
    _loadLatestImage();
  }

  Future<void> _loadLatestImage() async {
    try {
      final catalogItem = await _db.getCatalogItemById(widget.item.itemId);
      if (catalogItem != null && catalogItem.imageUrl != null && catalogItem.imageUrl!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _latestImageUrl = catalogItem.imageUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading latest image in order card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = _latestImageUrl ?? widget.item.imageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.item.type == 'product'
              ? const Color(0xFFE0E7FF)
              : const Color(0xFFFEF3C7),
          backgroundImage: ImageHelper.getImageProvider(displayImageUrl),
          child: displayImageUrl != null && displayImageUrl.isNotEmpty
              ? null
              : Icon(
                  widget.item.type == 'product' ? Icons.inventory : Icons.build,
                  color: widget.item.type == 'product' ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                  size: 20,
                ),
        ),
        title: Text(
          widget.item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${widget.item.quantity} x ₹${widget.item.price.toStringAsFixed(0)}',
        ),
        trailing: Text(
          '₹${widget.item.totalWithGst.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }
}
