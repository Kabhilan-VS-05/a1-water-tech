import 'package:flutter/material.dart';
import 'bill_view_screen.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  
  List<Bill> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final bills = await _db.getBills();
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
    
    // Background sync to ensure we have the latest
    try {
      await _sync.syncAll();
      final freshBills = await _db.getBills();
      if (mounted) {
        setState(() {
          _bills = freshBills;
        });
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _manualSync() async {
    await _sync.manualSync();
    await _loadBills();
  }

  Future<void> _viewBillDetails(Bill bill) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BillDetailsSheet(bill: bill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Billing History'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _manualSync,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = _bills[index];
                      return _PremiumBillCard(
                        bill: bill,
                        onTap: () => _viewBillDetails(bill),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: AppTheme.dividerColorLight),
          const SizedBox(height: 16),
          Text(
            'No bills generated yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _PremiumBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const _PremiumBillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_rounded, color: AppTheme.accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(bill.customerName, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(bill.createdAt), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${bill.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accentColor)),
                const SizedBox(height: 4),
                _StatusBadge(status: bill.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppTheme.secondaryColor;
        break;
      case 'pending':
        color = const Color(0xFFD97706);
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BillDetailsSheet extends StatelessWidget {
  final Bill bill;

  const _BillDetailsSheet({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice ID', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                      Text(bill.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Customer', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                      Text(bill.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Date', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                      Text(DateFormat('MMM dd, yyyy').format(bill.createdAt), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Status', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                      _StatusBadge(status: bill.status),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            // Items List
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bill.items.length,
                itemBuilder: (ctx, i) {
                  final item = bill.items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.name)),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 32),
            
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(color: AppTheme.textSecondaryLight)),
                Text('₹${bill.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (GST)', style: TextStyle(color: AppTheme.textSecondaryLight)),
                Text('₹${bill.gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${bill.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accentColor)),
              ],
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillViewScreen(
                        billId: bill.id,
                        isEditable: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                label: const Text('Edit / View Full Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print functionality coming soon')));
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share functionality coming soon')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Share Invoice', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Bill?'),
                      content: const Text('Are you sure you want to delete this bill? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true), 
                          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await DatabaseService().deleteBill(bill.id);
                    await SyncService().syncOnSave(); // Try to sync delete to cloud
                    if (context.mounted) {
                      Navigator.pop(context); // Close sheet
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill deleted')));
                      // Note: We need a way to refresh the list. 
                      // For now, assume the user will pull to refresh or the screen will re-load.
                    }
                  }
                },
                icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor),
                label: const Text('DELETE BILL', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
