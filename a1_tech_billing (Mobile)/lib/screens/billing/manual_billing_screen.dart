import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class ManualBillingScreen extends StatefulWidget {
  const ManualBillingScreen({super.key});

  @override
  State<ManualBillingScreen> createState() => _ManualBillingScreenState();
}

class _ManualBillingScreenState extends State<ManualBillingScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  
  late TabController _tabController;
  List<CatalogItem> _catalog = [];
  final List<BillItem> _cart = [];
  Customer? _selectedCustomer;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final products = await _db.getCatalogItems(type: 'product');
    final services = await _db.getCatalogItems(type: 'service');
    setState(() {
      _catalog = [...products, ...services];
      _isLoading = false;
    });
  }

  void _addToCart(CatalogItem item) {
    setState(() {
      final existingIndex = _cart.indexWhere((i) => i.itemId == item.id);
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        final newQty = existing.quantity + 1;
        final newSubtotal = existing.price * newQty;
        final newGstAmount = (newSubtotal * existing.gstPercent) / 100;
        
        _cart[existingIndex] = BillItem(
          itemId: existing.itemId,
          name: existing.name,
          type: existing.type,
          price: existing.price,
          quantity: newQty,
          gstPercent: existing.gstPercent,
          gstAmount: newGstAmount,
          total: newSubtotal + newGstAmount,
          imageUrl: existing.imageUrl,
        );
      } else {
        final qty = 1;
        final subtotal = item.price * qty;
        final gstAmount = (subtotal * item.gstPercent) / 100;
        
        _cart.add(BillItem(
          itemId: item.id,
          name: item.name,
          type: item.type,
          price: item.price,
          quantity: qty,
          gstPercent: item.gstPercent,
          gstAmount: gstAmount,
          total: subtotal + gstAmount,
          imageUrl: item.imageUrl,
        ));
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () => _tabController.animateTo(1),
        ),
      ),
    );
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final existing = _cart[index];
      final newQty = existing.quantity + delta;
      
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        final newSubtotal = existing.price * newQty;
        final newGstAmount = (newSubtotal * existing.gstPercent) / 100;
        
        _cart[index] = BillItem(
          itemId: existing.itemId,
          name: existing.name,
          type: existing.type,
          price: existing.price,
          quantity: newQty,
          gstPercent: existing.gstPercent,
          gstAmount: newGstAmount,
          total: newSubtotal + newGstAmount,
          imageUrl: existing.imageUrl,
        );
      }
    });
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _taxTotal => _cart.fold(0, (sum, item) => sum + item.gstAmount);
  double get _total => _subtotal + _taxTotal;

  Future<void> _generateBill() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    final now = DateTime.now();
    final bill = Bill(
      id: 'BILL-${now.millisecondsSinceEpoch}',
      billNumber: 'BILL-${now.millisecondsSinceEpoch}',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      subtotal: _subtotal,
      gstAmount: _taxTotal,
      total: _total,
      items: _cart,
      status: 'paid',
      paymentMode: 'cash',
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertBill(bill);
    await _sync.syncOnSave();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill created successfully!'), 
          backgroundColor: AppTheme.secondaryColor
        )
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectCustomer() async {
    final customers = await _db.getCustomers();
    if (!mounted) return;

    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Select Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: customers.length,
                itemBuilder: (ctx, i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                      child: Text(customers[i].name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentColor)),
                    ),
                    title: Text(customers[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(customers[i].phone ?? 'No phone'),
                    onTap: () => Navigator.pop(context, customers[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedCustomer = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCatalog = _catalog.where((item) => 
      item.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Add Items'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Final Bill'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Catalog
          Column(
            children: [
              _buildSearchField(),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCatalogList(filteredCatalog),
              ),
              if (_cart.isNotEmpty) _buildMiniCartBar(),
            ],
          ),
          
          // TAB 2: Cart/Checkout
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildCustomerCard()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Text(
                          'Items (${_cart.length})', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ),
                    ),
                    if (_cart.isEmpty)
                      const SliverFillRemaining(child: Center(child: Text('Your cart is empty')))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildCheckoutItem(i),
                            childCount: _cart.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildFinalSummary(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search products or services...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCatalogList(List<CatalogItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (item.type == 'product' ? Colors.blue : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.type == 'product' ? Icons.inventory_2_rounded : Icons.construction_rounded,
                color: item.type == 'product' ? AppTheme.accentColor : AppTheme.secondaryColor,
              ),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.accentColor, size: 30),
              onPressed: () => _addToCart(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniCartBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_cart.length} items added', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Total: ₹${_total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(1),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Row(
              children: [
                Text('Checkout'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return InkWell(
      onTap: _selectCustomer,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.accentColor.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppTheme.accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(_selectedCustomer?.name ?? 'Select Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  if (_selectedCustomer != null) Text(_selectedCustomer!.phone ?? ''),
                ],
              ),
            ),
            const Icon(Icons.edit_note, color: AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutItem(int i) {
    final item = _cart[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentColor)),
                ],
              ),
            ),
            Row(
              children: [
                _qtyBtn(Icons.remove, () => _updateQuantity(i, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _qtyBtn(Icons.add, () => _updateQuantity(i, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildFinalSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Subtotal', _subtotal),
            const SizedBox(height: 8),
            _summaryRow('Tax (GST)', _taxTotal, isTax: true),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.accentColor)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _cart.isEmpty || _selectedCustomer == null ? null : _generateBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('MAKE BILL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTax = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: isTax ? Colors.green : null)),
      ],
    );
  }
}
