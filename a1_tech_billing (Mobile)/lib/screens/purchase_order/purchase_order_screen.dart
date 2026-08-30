import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/logger_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/invoice_number_generator.dart';
import '../../widgets/error_dialog.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  List<PurchaseOrder> _allPOs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPOs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPOs() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _db.getPurchaseOrders();
      setState(() {
        _allPOs = pos;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load POs: $e', tag: 'PO');
      setState(() => _isLoading = false);
    }
  }

  List<PurchaseOrder> _getByStatus(String status) =>
      _allPOs.where((po) => po.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Draft'),
            Tab(icon: Icon(Icons.send), text: 'Sent'),
            Tab(icon: Icon(Icons.check_circle), text: 'Accepted'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPOList(_getByStatus('draft')),
                _buildPOList(_getByStatus('sent')),
                _buildPOList(_getByStatus('accepted')),
                _buildPOList(_getByStatus('rejected')),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePO(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPOList(List<PurchaseOrder> pos) {
    if (pos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: AppTheme.textSecondaryLight),
            SizedBox(height: 16),
            Text('No POs found', style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryLight)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pos.length,
      itemBuilder: (ctx, i) => _buildPOCard(pos[i]),
    );
  }

  Widget _buildPOCard(PurchaseOrder po) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(po.status),
          child: const Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${po.customerName} • ₹${po.total.toStringAsFixed(0)}'),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            PopupMenuItem(
              child: const Text('View Details'),
              onTap: () => _showPODetails(po),
            ),
            if (po.isDraft)
              PopupMenuItem(
                child: const Text('Send'),
                onTap: () => _updatePOStatus(po.id, 'sent'),
              ),
            if (po.isSent) ...[
              PopupMenuItem(
                child: const Text('Accept'),
                onTap: () => _updatePOStatus(po.id, 'accepted'),
              ),
              PopupMenuItem(
                child: const Text('Reject'),
                onTap: () => _updatePOStatus(po.id, 'rejected'),
              ),
            ],
          ],
        ),
        onTap: () => _showPODetails(po),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updatePOStatus(String poId, String newStatus) async {
    try {
      await _db.updatePurchaseOrderStatus(poId, newStatus);
      await _loadPOs();
      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          title: 'Updated',
          message: 'PO status updated to $newStatus',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update PO status: $e', tag: 'PO');
    }
  }

  void _showPODetails(PurchaseOrder po) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(po.poNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSectionHeader('Billing Address'),
            _buildAddressDisplay(po.billingAddress),
            const SizedBox(height: 16),
            _buildSectionHeader('Shipping Address'),
            _buildAddressDisplay(po.shippingAddress),
            const SizedBox(height: 16),
            _buildSectionHeader('Items (${po.items.length})'),
            ...po.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.name} x${item.quantity}'),
                  Text('₹${item.total.toStringAsFixed(0)}'),
                ],
              ),
            )),
            const Divider(height: 16),
            _buildDetailRow('Total', '₹${po.total.toStringAsFixed(2)}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildAddressDisplay(Address address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(address.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(address.street),
          Text('${address.city}, ${address.state} - ${address.zipCode}'),
          Text('Phone: ${address.phone}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryLight)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _navigateToCreatePO() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePOScreen()),
    );
  }
}

class CreatePOScreen extends StatefulWidget {
  const CreatePOScreen({super.key});

  @override
  State<CreatePOScreen> createState() => _CreatePOScreenState();
}

class _CreatePOScreenState extends State<CreatePOScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  List<CatalogItem> _catalog = [];
  final List<BillItem> _items = [];
  Customer? _selectedCustomer;
  late Address _billingAddress;
  late Address _shippingAddress;
  late TextEditingController _paymentTermsController;
  late TextEditingController _notesController;
  bool _isLoading = true;
  bool _useSameAddress = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paymentTermsController = TextEditingController();
    _notesController = TextEditingController();
    _billingAddress = _createEmptyAddress('billing');
    _shippingAddress = _createEmptyAddress('shipping');
    _loadCatalog();
  }

  Address _createEmptyAddress(String type) {
    return Address(
      id: 'temp_$type',
      name: '',
      street: '',
      city: '',
      state: '',
      zipCode: '',
      phone: '',
      type: type,
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final products = await _db.getCatalogItems(type: 'product');
      final services = await _db.getCatalogItems(type: 'service');
      setState(() {
        _catalog = [...products, ...services];
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load catalog: $e', tag: 'PO');
      setState(() => _isLoading = false);
    }
  }

  void _addItemToPO(CatalogItem item) {
    final qty = 1;
    final subtotal = item.price * qty;
    final gstAmount = (subtotal * item.gstPercent) / 100;

    setState(() {
      _items.add(BillItem(
        itemId: item.id,
        name: item.name,
        type: item.type,
        price: item.price,
        quantity: qty,
        gstPercent: item.gstPercent,
        gstAmount: gstAmount,
        total: subtotal + gstAmount,
        imageUrl: item.imageUrl,
        hsn: item.hsn,
      ));
    });

    AppDialogs.showSnackBar(context, message: '${item.name} added to PO');
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _taxTotal => _items.fold(0, (sum, item) => sum + item.gstAmount);
  double get _total => _subtotal + _taxTotal;

  Future<void> _selectCustomer() async {
    final customers = await _db.getCustomers();
    if (!mounted) return;

    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...customers.map((customer) => ListTile(
            title: Text(customer.name),
            subtitle: Text(customer.phone ?? 'No phone'),
            onTap: () => Navigator.pop(ctx, customer),
          )),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        if (_useSameAddress) {
          _updateBothAddressesFromCustomer(selected);
        }
      });
    }
  }

  void _updateBothAddressesFromCustomer(Customer customer) {
    final addr = customer.address ?? '';
    _billingAddress = Address(
      id: 'billing_${customer.id}',
      customerId: customer.id,
      name: customer.name,
      street: addr.split(',').isNotEmpty ? addr.split(',')[0].trim() : '',
      city: '',
      state: '',
      zipCode: '',
      phone: customer.phone ?? '',
      type: 'billing',
      createdAt: DateTime.now(),
    );
    _shippingAddress = _billingAddress.copyWith(
      id: 'shipping_${customer.id}',
      type: 'shipping',
    );
  }

  void _editAddress(bool isBilling) {
    final address = isBilling ? _billingAddress : _shippingAddress;
    showDialog(
      context: context,
      builder: (ctx) => _AddressEditDialog(
        address: address,
        onSave: (updatedAddress) {
          setState(() {
            if (isBilling) {
              _billingAddress = updatedAddress;
            } else {
              _shippingAddress = updatedAddress;
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _savePO() async {
    if (_selectedCustomer == null) {
      AppDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'Please select a customer',
      );
      return;
    }

    if (_items.isEmpty) {
      AppDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'Please add at least one item',
      );
      return;
    }

    try {
      final now = DateTime.now();
      final poNumber = await InvoiceNumberGenerator.generatePurchaseOrderNumber();

      final po = PurchaseOrder(
        id: poNumber,
        poNumber: poNumber,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phone,
        billingAddress: _billingAddress,
        shippingAddress: _shippingAddress,
        items: _items,
        subtotal: _subtotal,
        gstAmount: _taxTotal,
        total: _total,
        paymentTerms: _paymentTermsController.text.isNotEmpty
            ? _paymentTermsController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      );

      await _db.insertPurchaseOrder(po);
      AppLogger.info('PO created: $poNumber', tag: 'PO');

      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          title: 'Success',
          message: 'PO created: $poNumber',
          onAction: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save PO: $e', tag: 'PO');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PO', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Items'),
            Tab(icon: Icon(Icons.description), text: 'Details'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogTab(),
                _buildDetailsTab(),
              ],
            ),
    );
  }

  Widget _buildCatalogTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _catalog.length,
      itemBuilder: (ctx, i) {
        final item = _catalog[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('₹${item.price} • ${item.type}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.accentColor),
              onPressed: () => _addItemToPO(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: InkWell(
                    onTap: _selectCustomer,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_selectedCustomer?.name ?? 'Tap to select customer',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: const Text('Use same address for billing & shipping'),
                    ),
                    Switch(
                      value: _useSameAddress,
                      onChanged: (val) => setState(() => _useSameAddress = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAddressSection('Billing Address', _billingAddress, true),
                const SizedBox(height: 16),
                if (!_useSameAddress)
                  _buildAddressSection('Shipping Address', _shippingAddress, false),
                const SizedBox(height: 16),
                TextField(
                  controller: _paymentTermsController,
                  decoration: InputDecoration(
                    labelText: 'Payment Terms',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Items (${_items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${_items[i].name} x${_items[i].quantity}')),
                  Text('₹${_items[i].total.toStringAsFixed(0)}'),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                ],
              ),
            ),
            childCount: _items.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('Total'), Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _savePO,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Save PO', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(String title, Address address, bool isBilling) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => _editAddress(isBilling),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
              child: const Text('Edit', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address.name.isEmpty ? 'No name' : address.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(address.street.isEmpty ? 'No street' : address.street),
              Text(address.city.isEmpty ? 'No city' : '${address.city}, ${address.state} - ${address.zipCode}'),
              Text('Phone: ${address.phone.isEmpty ? 'No phone' : address.phone}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressEditDialog extends StatefulWidget {
  final Address address;
  final Function(Address) onSave;

  const _AddressEditDialog({required this.address, required this.onSave});

  @override
  State<_AddressEditDialog> createState() => _AddressEditDialogState();
}

class _AddressEditDialogState extends State<_AddressEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address.name);
    _streetController = TextEditingController(text: widget.address.street);
    _cityController = TextEditingController(text: widget.address.city);
    _stateController = TextEditingController(text: widget.address.state);
    _zipController = TextEditingController(text: widget.address.zipCode);
    _phoneController = TextEditingController(text: widget.address.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: _streetController, decoration: const InputDecoration(labelText: 'Street')),
            const SizedBox(height: 8),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 8),
            TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State')),
            const SizedBox(height: 8),
            TextField(controller: _zipController, decoration: const InputDecoration(labelText: 'ZIP Code')),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final updatedAddress = widget.address.copyWith(
              name: _nameController.text,
              street: _streetController.text,
              city: _cityController.text,
              state: _stateController.text,
              zipCode: _zipController.text,
              phone: _phoneController.text,
            );
            widget.onSave(updatedAddress);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
