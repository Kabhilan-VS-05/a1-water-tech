import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';

class CustomerSearchDialog extends StatefulWidget {
  const CustomerSearchDialog({super.key});

  @override
  State<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<CustomerSearchDialog> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _db.getCustomers();
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _search(String query) async {
    final customers = await _db.getCustomers(search: query);
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _addNewCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (ctx) => const AddCustomerDialog(),
    );

    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCustomers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _customers.isEmpty
                        ? const Center(child: Text('No customers found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _customers.length,
                            itemBuilder: (ctx, index) {
                              final customer = _customers[index];
                              final isWebsite = customer.source == 'website';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isWebsite
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFE0E7FF),
                                  child: Icon(
                                    isWebsite ? Icons.language : Icons.person,
                                    color: isWebsite
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF4F46E5),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    if (isWebsite)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Website Account',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  isWebsite && customer.email != null
                                      ? '${customer.phone ?? ''} • ${customer.email}'
                                      : customer.phone ?? 'No phone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: customer.totalVisits > 0
                                    ? Chip(
                                        label: Text(
                                          '${customer.totalVisits} visits',
                                        ),
                                        backgroundColor: Colors.green.shade100,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(context, customer),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _addNewCustomer,
          icon: const Icon(Icons.add),
          label: const Text('New Customer'),
        ),
      ],
    );
  }
}

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if phone already exists
    if (_phoneController.text.isNotEmpty) {
      final existing = await _db.getCustomerByPhone(_phoneController.text);
      if (existing != null && mounted) {
        final useExisting = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Customer Exists'),
            content: Text(
              '${existing.name} with this phone already exists. Use existing?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Create New'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Use Existing'),
              ),
            ],
          ),
        );

        if (useExisting == true) {
          Navigator.pop(context, existing);
          return;
        }
      }
    }

    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      createdAt: DateTime.now(),
    );

    await _db.insertCustomer(customer);

    if (mounted) {
      Navigator.pop(context, customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '10 digit mobile number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final DatabaseService _db = DatabaseService();
  List<CatalogItem> _products = [];
  List<CatalogItem> _services = [];
  int _selectedQuantity = 1;
  CatalogItem? _selectedItem;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final products = await _db.getCatalogItems(type: 'product');
    final services = await _db.getCatalogItems(type: 'service');
    setState(() {
      _products = products;
      _services = services;
    });
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selectedItem = item;
    });
  }

  void _confirmSelection() {
    if (_selectedItem != null) {
      Navigator.pop(context, {
        'item': _selectedItem,
        'quantity': _selectedQuantity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Tab Selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Products'),
                  icon: Icon(Icons.inventory),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Services'),
                  icon: Icon(Icons.build),
                ),
              ],
              selected: {_currentTab},
              onSelectionChanged: (value) {
                setState(() {
                  _currentTab = value.first;
                  _selectedItem = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: _currentTab == 0
                  ? _buildItemList(_products, Colors.blue)
                  : _buildItemList(_services, Colors.orange),
            ),

            // Quantity Selector (only for selected item)
            if (_selectedItem != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedItem!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_selectedItem!.price.toStringAsFixed(0)} + ${_selectedItem!.gstPercent}% GST',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: _selectedQuantity > 1
                            ? () => setState(() => _selectedQuantity--)
                            : null,
                      ),
                      Text(
                        '$_selectedQuantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () => setState(() => _selectedQuantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedItem != null ? _confirmSelection : null,
          child: const Text('Add to Bill'),
        ),
      ],
    );
  }

  Widget _buildItemList(List<CatalogItem> items, Color color) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items available. Add items in Catalog.'),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        final isSelected = _selectedItem?.id == item.id;

        return Card(
          color: isSelected ? color.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              backgroundImage: ImageHelper.getImageProvider(item.imageUrl),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? null
                  : Icon(
                      _currentTab == 0 ? Icons.inventory : Icons.build,
                      color: color,
                    ),
            ),
            title: Text(item.name),
            subtitle: Text(item.category ?? 'No category'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '+${item.gstPercent.toStringAsFixed(0)}% GST',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            onTap: () => _selectItem(item),
          ),
        );
      },
    );
  }
}
