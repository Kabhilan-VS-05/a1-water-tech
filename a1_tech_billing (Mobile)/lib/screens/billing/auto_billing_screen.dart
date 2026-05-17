import '../../utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/image_helper.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Order) {
      setState(() {
        _order = args;
        _isLoading = false;
      });
    } else {
      // If no order passed, go back
      Navigator.pop(context);
    }
  }

  Future<void> _generateBill() async {
    if (_order == null) return;

    setState(() => _isGenerating = true);

    final now = DateTime.now();
    final billNumber =
        'BILL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    // Convert order items to bill items
    final billItems = _order!.items.map((orderItem) {
      return BillItem(
        itemId: orderItem.itemId,
        name: orderItem.name,
        type: orderItem.type,
        price: orderItem.price,
        quantity: orderItem.quantity,
        gstPercent: orderItem.gstPercent,
        gstAmount: orderItem.gstAmount,
        total: orderItem.totalWithGst,
        imageUrl: orderItem.imageUrl,
      );
    }).toList();

    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      billNumber: billNumber,
      customerName: _order!.customerName,
      customerPhone: _order!.customerPhone,
      customerAddress: _order!.customerAddress,
      items: billItems,
      subtotal: _order!.subtotal,
      gstAmount: _order!.gstAmount,
      total: _order!.total,
      paymentMode: 'pending',
      status: 'draft',
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
        final pdfFile = await PdfService.generateInvoice(bill);
        await Printing.layoutPdf(
          name: 'Invoice_$billNumber',
          onLayout: (format) => pdfFile,
        );
      } catch (e) {
        print('PDF generation error: $e');
      }

      Navigator.pushReplacementNamed(context, '/dashboard');
    }
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
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order #${_order!.orderId ?? (_order!.id.length > 8 ? _order!.id.substring(0, 8).toUpperCase() : _order!.id.toUpperCase())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateBill,
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
          Icon(icon, size: 16, color: Colors.grey.shade600),
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
            'Rs. ${amount.toStringAsFixed(0)}',
            style: isBold
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF4F46E5),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.type == 'product'
              ? const Color(0xFFE0E7FF)
              : const Color(0xFFFEF3C7),
          backgroundImage: ImageHelper.getImageProvider(item.imageUrl),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? null
              : Icon(
                  item.type == 'product' ? Icons.inventory : Icons.build,
                  color: item.type == 'product' ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                  size: 20,
                ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${item.quantity} x Rs. ${item.price.toStringAsFixed(0)}',
        ),
        trailing: Text(
          'Rs. ${item.totalWithGst.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }
}
