import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'bill_view_screen.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
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

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    await _sync.forceSyncAllBillsToCloud();
    await _loadBills();
  }

  Future<void> _viewBillDetails(Bill bill) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BillDetailsSheet(
        bill: bill,
        onDeleted: _loadBills, // Refresh list immediately after delete
      ),
    );
  }

  List<Bill> get _filteredBills {
    List<Bill> list = List.from(_bills);
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((b) {
        final matchesBasic = b.id.toLowerCase().contains(query) ||
            b.billNumber.toLowerCase().contains(query) ||
            b.customerName.toLowerCase().contains(query) ||
            (b.customerPhone?.toLowerCase().contains(query) ?? false) ||
            (b.customerAddress?.toLowerCase().contains(query) ?? false) ||
            b.paymentMode.toLowerCase().contains(query) ||
            b.status.toLowerCase().contains(query);
            
        final matchesItems = b.items.any((item) =>
            item.itemId.toLowerCase().contains(query) ||
            item.name.toLowerCase().contains(query) ||
            item.type.toLowerCase().contains(query) ||
            (item.hsn?.toLowerCase().contains(query) ?? false));
            
        return matchesBasic || matchesItems;
      }).toList();
    }
    
    if (_selectedDateRange != null) {
      list = list.where((b) {
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return b.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) && b.createdAt.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }
    
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Widget _buildSearchAndFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bill ID, customer, item...',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondaryLight.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _selectedDateRange != null 
                      ? AppTheme.accentColor.withOpacity(0.1) 
                      : (isDark ? Colors.grey[900] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDateRange != null 
                        ? AppTheme.accentColor 
                        : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _selectedDateRange != null ? Icons.date_range_rounded : Icons.calendar_today_rounded,
                    color: _selectedDateRange != null ? AppTheme.accentColor : AppTheme.textSecondaryLight,
                    size: 20,
                  ),
                  onPressed: _selectDateRange,
                ),
              ),
            ],
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 14,
                    color: AppTheme.accentColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _getDateGroupHeader(DateTime date, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final dateStart = DateTime(date.year, date.month, date.day);

    if (dateStart == todayStart) {
      return 'Today';
    } else if (dateStart == yesterdayStart) {
      return 'Yesterday';
    }

    final differenceInDays = todayStart.difference(dateStart).inDays;

    if (differenceInDays > 1 && differenceInDays < 7) {
      return DateFormat('EEEE').format(date); // e.g. Thursday, Wednesday, Tuesday
    } else if (differenceInDays >= 7 && differenceInDays < 14) {
      return 'Last Week';
    } else if (date.year == now.year) {
      return DateFormat('MMMM').format(date); // e.g. June, May, April
    } else {
      return DateFormat('yyyy').format(date); // e.g. 2025, 2024
    }
  }

  List<_GroupedHistoryItem> get _groupedFilteredBills {
    final bills = _filteredBills;
    final List<_GroupedHistoryItem> items = [];
    final now = DateTime.now();
    String? lastHeader;

    for (final bill in bills) {
      final header = _getDateGroupHeader(bill.createdAt, now);
      if (header != lastHeader) {
        items.add(_GroupedHistoryItem(groupHeader: header, bill: bill));
        lastHeader = header;
      } else {
        items.add(_GroupedHistoryItem(groupHeader: null, bill: bill));
      }
    }
    return items;
  }

  Widget _buildGroupHeader(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupedFilteredBills;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Billing History'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterRow(),
                Expanded(
                  child: _filteredBills.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _manualSync,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: groupedItems.length,
                            itemBuilder: (context, index) {
                              final item = groupedItems[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.groupHeader != null)
                                    _buildGroupHeader(item.groupHeader!),
                                  _PremiumBillCard(
                                    bill: item.bill,
                                    onTap: () => _viewBillDetails(item.bill),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final bool isFiltered = _searchQuery.isNotEmpty || _selectedDateRange != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.receipt_long_rounded,
            size: 80,
            color: AppTheme.dividerColorLight,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching results' : 'No bills generated yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryLight),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or date filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryLight),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupedHistoryItem {
  final String? groupHeader;
  final Bill bill;

  _GroupedHistoryItem({this.groupHeader, required this.bill});
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bill.billNumber.isNotEmpty ? bill.billNumber : bill.id, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: bill.isSynced ? 'Synced to Cloud' : 'Local Only (Pending Sync)',
                        child: Icon(
                          bill.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 16,
                          color: bill.isSynced 
                              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF10B981) : Colors.green[700])
                              : AppTheme.errorColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
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
  final VoidCallback? onDeleted; // Callback to refresh parent list

  const _BillDetailsSheet({required this.bill, this.onDeleted});

  Future<bool?> _showSignatureDialog(BuildContext context) async {
    return showDialog<bool>(
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
  }

  Future<void> _printBill(BuildContext context) async {
    try {
      final isDigital = await _showSignatureDialog(context);
      if (isDigital == null) return;
      final pdfFile = await PdfService.generateInvoice(bill, isDigitalSignature: isDigital);
      await Printing.layoutPdf(onLayout: (_) async => pdfFile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _shareBill(BuildContext context) async {
    try {
      final isDigital = await _showSignatureDialog(context);
      if (isDigital == null) return;
      final pdfFile = await PdfService.generateInvoice(bill, isDigitalSignature: isDigital);
      await Printing.sharePdf(
        bytes: pdfFile,
        filename: '${bill.billNumber.isNotEmpty ? bill.billNumber : bill.id}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice ID', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                          Text(
                            bill.id,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Date', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                          Text(
                            DateFormat('MMM dd, yyyy').format(bill.createdAt),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                            Text(
                              bill.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Status', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                          _StatusBadge(status: bill.status),
                        ],
                      ),
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
                    onPressed: () => _printBill(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareBill(context),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bill deleted')),
                      );
                      onDeleted?.call(); // Refresh the parent list
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
