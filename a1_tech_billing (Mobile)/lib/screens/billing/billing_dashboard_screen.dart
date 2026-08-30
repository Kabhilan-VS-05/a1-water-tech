import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import 'bill_view_screen.dart';
import 'manual_billing_screen.dart';

class BillingDashboardScreen extends StatefulWidget {
  final bool? showAppBar;
  const BillingDashboardScreen({super.key, this.showAppBar = true});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  List<Bill> _bills = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    final list = await _db.getBills();
    if (mounted) {
      setState(() {
        _bills = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _bills.where((b) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return b.billNumber.toLowerCase().contains(query) ||
          b.customerName.toLowerCase().contains(query) ||
          (b.customerPhone != null && b.customerPhone!.contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: (widget.showAppBar ?? true) ? AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Invoice List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ) : null,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by Name, Company OR Invoice#',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'You don\'t have any invoices',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final bill = filtered[i];
                          return Card(
                            clipBehavior: Clip.hardEdge,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bill.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '₹${bill.total.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${bill.billNumber} • ${DateFormat('dd/MM/yyyy').format(bill.createdAt)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bill.status == 'paid' ? Colors.green.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bill.status.toUpperCase(),
                                        style: TextStyle(
                                          color: bill.status == 'paid' ? Colors.green.shade800 : Colors.amber.shade900,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => BillViewScreen(bill: bill)),
                                ).then((_) => _loadBills());
                              },
                            ),
                            );
                          },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE91E63), // Pink FAB matching video
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('MAKE INVOICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManualBillingScreen()),
          ).then((_) => _loadBills());
        },
      ),
    );
  }
}
