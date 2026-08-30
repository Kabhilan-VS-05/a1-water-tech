import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_filterCustomers);
    _searchController.addListener(_filterCustomers);
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _db.getCustomers();
    setState(() {
      _customers = customers;
      _isLoading = false;
      _filterCustomers();
    });
    _backgroundSync();
  }

  Future<void> _backgroundSync() async {
    try {
      await _sync.syncAll();
      final freshCustomers = await _db.getCustomers();
      if (mounted) {
        setState(() {
          _customers = freshCustomers;
          _filterCustomers();
        });
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    final isWebsiteTab = _tabController.index == 0; // Tab 0 is Online Clients

    setState(() {
      _filteredCustomers = _customers.where((c) {
        final matchesQuery = c.name.toLowerCase().contains(query) || (c.phone?.toLowerCase().contains(query) ?? false);
        
        if (isWebsiteTab) {
          return matchesQuery && c.source != 'manual';
        } else {
          return matchesQuery && c.source == 'manual';
        }
      }).toList();
    });
  }

  Future<void> _addNewCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (ctx) => const _AddCustomerDialog(),
    );

    if (result != null) {
      await _db.insertCustomer(result);
      _loadCustomers();
      await _sync.syncOnSave();
    }
  }

  Future<void> _viewCustomerDetail(Customer customer) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerDetailSheet(
        customer: customer,
        onEdit: () => _editCustomer(customer),
        onDelete: () => _deleteCustomer(customer),
      ),
    );
  }

  Future<void> _editCustomer(Customer customer) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (ctx) => _AddCustomerDialog(customer: customer),
    );

    if (result != null) {
      await _db.updateCustomer(result);
      _loadCustomers();
      await _sync.syncOnSave();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This will not delete their bills.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteCustomer(customer.id);
      _loadCustomers();
      await _sync.syncOnSave();
      if (mounted) Navigator.pop(context); // Close sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients by name or phone...',
              hintStyle: TextStyle(color: AppTheme.textSecondaryLight),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.accentColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Online Clients'),
            Tab(text: 'Walk-in / Manual Clients'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: _filteredCustomers.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: _filteredCustomers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        return _PremiumCustomerCard(
                          customer: _filteredCustomers[index],
                          onTap: () => _viewCustomerDetail(_filteredCustomers[index]),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers_fab',
        onPressed: _addNewCustomer,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD CUSTOMER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_rounded, size: 80, color: AppTheme.dividerColorLight),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'No clients found' : 'No matching results',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class _PremiumCustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _PremiumCustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? const Color(0xFF334155) : AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Text(
                      customer.phone!,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                  if (customer.email != null && customer.email!.isNotEmpty)
                    Text(
                      customer.email!,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomerDialog extends StatefulWidget {
  final Customer? customer;
  const _AddCustomerDialog({this.customer});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _emailController = TextEditingController(text: widget.customer?.email);
    _addressController = TextEditingController(text: widget.customer?.address);
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final customer = widget.customer?.copyWith(
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      ) ?? Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        source: 'manual',
        createdAt: DateTime.now(),
      );
      Navigator.pop(context, customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                        child: const Text('Save Customer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerDetailSheet({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      if (customer.email != null) Text(customer.email!, style: TextStyle(color: AppTheme.textSecondaryLight)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (customer.source == 'manual') ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.accentColor),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                        onPressed: onDelete,
                      ),
                    ],
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _InfoCard(title: 'Total Spent', value: '₹${customer.totalSpent.toStringAsFixed(0)}', icon: Icons.currency_rupee)),
                const SizedBox(width: 16),
                Expanded(child: _InfoCard(title: 'Orders', value: '${customer.totalVisits}', icon: Icons.shopping_bag_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (customer.phone != null) ListTile(leading: const Icon(Icons.phone), title: Text(customer.phone!)),
            if (customer.address != null) ListTile(leading: const Icon(Icons.location_on), title: Text(customer.address!)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentColor),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
        ],
      ),
    );
  }
}
