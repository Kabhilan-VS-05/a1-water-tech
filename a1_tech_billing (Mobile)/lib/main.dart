import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Simple Admin App - Easy to Use
const String kApiBaseUrl = 'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin';
const String kCognitoPoolId = 'ap-south-1_frjBbY5H9';
const String kCognitoClientId = '7ipnh0krocrne8a98n5kecdtg0';

// S3 Image Upload Constants
const String kCatalogImageBucket = 'a1-water-tech';
const String kCatalogImageRegion = 'ap-southeast-2';
const String kCatalogImagePrefix = 'Images';

void main() {
  runApp(const SimpleAdminApp());
}

// ==================== MAIN APP ====================
class SimpleAdminApp extends StatelessWidget {
  const SimpleAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A1 Water - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'A1 Water Tech',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Admin App',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _doLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simple mock login for now
      await Future.delayed(const Duration(seconds: 1));
      
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _error = 'Please enter email and password');
        return;
      }

      // Save login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_email', _emailController.text);
      await prefs.setBool('is_logged_in', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Login failed. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// ==================== HOME SCREEN - SIMPLE 4 BUTTONS ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A1 Water Admin'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            Text(
              'Hello Admin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What do you want to do?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // 4 Big Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _BigMenuButton(
                    icon: Icons.receipt_long,
                    label: 'New Bill',
                    color: Colors.green,
                    onTap: () => _openNewBill(context),
                  ),
                  _BigMenuButton(
                    icon: Icons.list_alt,
                    label: 'My Bills',
                    color: Colors.blue,
                    onTap: () => _openMyBills(context),
                  ),
                  _BigMenuButton(
                    icon: Icons.shopping_bag,
                    label: 'Orders',
                    color: Colors.orange,
                    onTap: () => _openOrders(context),
                  ),
                  _BigMenuButton(
                    icon: Icons.inventory_2,
                    label: 'Catalog',
                    color: Colors.purple,
                    onTap: () => _openCatalog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Yes, Exit'),
          ),
        ],
      ),
    );
  }

  void _openNewBill(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewBillScreen()),
    );
  }

  void _openMyBills(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyBillsScreen()),
    );
  }

  void _openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  void _openCatalog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatalogManagerScreen()),
    );
  }
}

// ==================== BIG MENU BUTTON WIDGET ====================
class _BigMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _BigMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade400, color.shade700],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== NEW BILL SCREEN ====================
class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final List<Map<String, dynamic>> _items = [];
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  
  double get _total => _items.fold(0, (sum, item) => sum + (item['price'] * item['qty']));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Customer info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Customer Phone',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          
          // Items list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No items added yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(_items[i]['name']),
                        subtitle: Text('₹${_items[i]['price']} x ${_items[i]['qty']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${(_items[i]['price'] * _items[i]['qty']).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(i),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          
          // Total and Save
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _items.isEmpty ? null : _saveBill,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => _AddItemDialog(
        onAdd: (name, price, qty) {
          setState(() {
            _items.add({'name': name, 'price': price, 'qty': qty});
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _saveBill() {
    // TODO: Save to API
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bill Saved!'),
        content: Text('Total: ₹${_total.toStringAsFixed(0)}\n\nBill saved successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ==================== ADD ITEM DIALOG ====================
class _AddItemDialog extends StatefulWidget {
  final Function(String name, double price, int qty) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Water Purifier',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price (₹)',
              hintText: 'e.g., 15000',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text;
            final price = double.tryParse(_priceController.text) ?? 0;
            final qty = int.tryParse(_qtyController.text) ?? 1;
            if (name.isNotEmpty && price > 0) {
              widget.onAdd(name, price, qty);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ==================== MY BILLS SCREEN ====================
class MyBillsScreen extends StatelessWidget {
  const MyBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bills'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.receipt, color: Colors.blue),
            ),
            title: Text('Bill #${1001 + i}'),
            subtitle: Text('Customer ${i + 1} • ${DateTime.now().toString().split(' ')[0]}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${(15000 + i * 1000).toString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'print') {
                      _showSimpleMessage(context, 'Printing bill...');
                    } else if (value == 'share') {
                      _showSimpleMessage(context, 'Sharing bill...');
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'print', child: Text('Print')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSimpleMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

// ==================== ORDERS SCREEN ====================
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Orders'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (ctx, i) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.shopping_bag, color: Colors.orange),
                      ),
                      title: Text('Order #${_orders[i]['orderId'] ?? i}'),
                      subtitle: Text(_orders[i]['customer']?['fullName'] ?? 'Customer'),
                      trailing: ElevatedButton(
                        onPressed: () => _confirmOrder(_orders[i]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ),
                ),
    );
  }

  void _confirmOrder(dynamic order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Details'),
        content: Text('Order: ${order['orderId'] ?? 'N/A'}\n\nConfirm this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSimpleMessage('Order confirmed!');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

// ==================== CATALOG MANAGER SCREEN ====================
class CatalogManagerScreen extends StatefulWidget {
  const CatalogManagerScreen({super.key});

  @override
  State<CatalogManagerScreen> createState() => _CatalogManagerScreenState();
}

class _CatalogManagerScreenState extends State<CatalogManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('Loading from API: $kApiBaseUrl');
      
      // Try public endpoints first (no auth required)
      final baseApiUrl = kApiBaseUrl.replaceAll('/admin', '');
      
      // Load products from public API
      final productsUrl = Uri.parse('$baseApiUrl/products');
      debugPrint('Fetching products from: $productsUrl');
      final productsResponse = await http.get(productsUrl);
      debugPrint('Products response: ${productsResponse.statusCode}');
      
      // Load services from public API  
      final servicesUrl = Uri.parse('$baseApiUrl/services');
      debugPrint('Fetching services from: $servicesUrl');
      final servicesResponse = await http.get(servicesUrl);
      debugPrint('Services response: ${servicesResponse.statusCode}');

      setState(() {
        if (productsResponse.statusCode == 200) {
          final data = jsonDecode(productsResponse.body);
          _products = List<Map<String, dynamic>>.from(data['items'] ?? []);
          debugPrint('Loaded ${_products.length} products');
        } else {
          debugPrint('Products failed: ${productsResponse.body}');
          _products = [];
        }

        if (servicesResponse.statusCode == 200) {
          final data = jsonDecode(servicesResponse.body);
          _services = List<Map<String, dynamic>>.from(data['items'] ?? []);
          debugPrint('Loaded ${_services.length} services');
        } else {
          debugPrint('Services failed: ${servicesResponse.body}');
          _services = [];
        }

        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading catalog: $e');
      debugPrint('Stack: $stack');
      setState(() {
        _products = [];
        _services = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Catalog'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
            Tab(icon: Icon(Icons.home_repair_service), text: 'Services'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductTab(),
                _buildServiceTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditProductDialog();
          } else {
            _showAddEditServiceDialog();
          }
        },
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Product' : 'Add Service'),
      ),
    );
  }

  Widget _buildProductTab() {
    if (_products.isEmpty) {
      return _buildEmptyState('No products yet', 'Add your first product');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
    );
  }

  Widget _buildServiceTab() {
    if (_services.isEmpty) {
      return _buildEmptyState('No services yet', 'Add your first service');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (ctx, i) => _buildServiceCard(_services[i]),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Image area
          GestureDetector(
            onTap: () => _showImageOptions(product, isProduct: true),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        '${product['imageUrl']}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                        key: ValueKey(product['imageUrl']),
                        headers: const {'Cache-Control': 'no-cache'},
                        errorBuilder: (ctx, err, stack) {
                          debugPrint('Image error: $err');
                          return _buildImagePlaceholder();
                        },
                      ),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${(double.tryParse(product['price'].toString()) ?? 0).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product['category'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['description'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEditProductDialog(product: product),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _uploadImage(product, isProduct: true),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Image area
          GestureDetector(
            onTap: () => _showImageOptions(service, isProduct: false),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        '${service['imageUrl']}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                        key: ValueKey(service['imageUrl']),
                        headers: const {'Cache-Control': 'no-cache'},
                        errorBuilder: (ctx, err, stack) {
                          debugPrint('Image error: $err');
                          return _buildImagePlaceholder(isService: true);
                        },
                      ),
                    )
                  : _buildImagePlaceholder(isService: true),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (double.tryParse(service['price'].toString()) ?? 0) == 0
                            ? 'FREE'
                            : '₹${(double.tryParse(service['price'].toString()) ?? 0).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      service['duration'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service['description'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEditServiceDialog(service: service),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _uploadImage(service, isProduct: false),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder({bool isService = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isService ? Icons.home_repair_service : Icons.inventory_2,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add photo',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showImageOptions(Map<String, dynamic> item, {required bool isProduct}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _uploadImage(item, isProduct: isProduct, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _uploadImage(item, isProduct: isProduct, fromCamera: false);
              },
            ),
            if (item['imageUrl'] != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeImage(item, isProduct: isProduct);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(Map<String, dynamic> item, {
    required bool isProduct,
    bool fromCamera = false,
  }) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening...')),
      );

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      // Show uploading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo...')),
      );

      // Upload to S3
      final String collection = isProduct ? 'products' : 'services';
      final String? imageUrl = await _uploadToS3(
        pickedFile,
        collection: collection,
        existingId: item['id'],
      );

      if (imageUrl != null) {
        setState(() {
          item['imageUrl'] = imageUrl;
        });
        
        // Save imageUrl to database
        final bool saved = isProduct
            ? await _saveProduct(
                isEdit: true,
                docId: item['docId'] ?? item['id'],
                name: item['name'] ?? '',
                price: double.tryParse(item['price'].toString()) ?? 0,
                category: item['category'] ?? 'Purifiers',
                description: item['description'] ?? '',
                imageUrl: imageUrl,
              )
            : await _saveService(
                isEdit: true,
                docId: item['docId'] ?? item['id'],
                name: item['name'] ?? '',
                price: double.tryParse(item['price'].toString()) ?? 0,
                duration: item['duration'] ?? '1 hour',
                description: item['description'] ?? '',
                imageUrl: imageUrl,
              );
        
        if (saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded and saved!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded but failed to save to database')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<String?> _uploadToS3(
    XFile file, {
    required String collection,
    String? existingId,
  }) async {
    try {
      // Read file bytes
      final bytes = await file.readAsBytes();
      
      // Determine extension
      final String extension = file.name.split('.').last.toLowerCase();
      final String safeExtension = extension.isEmpty ? 'jpg' : extension;
      
      // Create unique filename
      final String objectId = existingId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String objectPath = '$kCatalogImagePrefix/$collection-$objectId.$safeExtension';
      
      // Build S3 URL
      final Uri uploadUri = Uri.https(
        '$kCatalogImageBucket.s3.$kCatalogImageRegion.amazonaws.com',
        '/$objectPath',
      );

      // Upload to S3 (bucket has public policy, no ACL needed)
      final response = await http.put(
        uploadUri,
        headers: {
          'Content-Type': 'image/$safeExtension',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        // Return public URL
        return 'https://$kCatalogImageBucket.s3.$kCatalogImageRegion.amazonaws.com/$objectPath';
      } else {
        debugPrint('S3 upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _removeImage(Map<String, dynamic> item, {required bool isProduct}) {
    setState(() {
      item['imageUrl'] = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo removed')),
    );
  }

  void _showAddEditProductDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final descController = TextEditingController(text: product?['description'] ?? '');
    final categoryController = TextEditingController(text: product?['category'] ?? 'Purifiers');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Aqua Pure Pro',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹) *',
                  hintText: 'e.g., 15000',
                  prefixText: '₹',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Purifiers, Filters',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the product...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final productDocId = isEdit ? (product['docId'] ?? product['id']) : null;
              final productImageUrl = isEdit ? product['imageUrl'] : null;
              
              _saveProduct(
                isEdit: isEdit,
                docId: productDocId,
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0,
                category: categoryController.text,
                description: descController.text,
                imageUrl: productImageUrl,
              ).then((success) {
                if (success) {
                  Navigator.pop(ctx);
                  _loadData(); // Refresh from API
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Product updated!' : 'Product added!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save. Try again.')),
                  );
                }
              });
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Product'),
          ),
        ],
      ),
    );
  }

  Future<bool> _saveProduct({
    required bool isEdit,
    String? docId,
    required String name,
    required double price,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final payload = {
        'docId': docId,
        'name': name,
        'price': price,
        'category': category.isEmpty ? 'Purifiers' : category,
        'description': description,
        'imageUrl': imageUrl,
      };

      final response = await http.post(
        Uri.parse('$kApiBaseUrl/catalog/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      debugPrint('Save product response: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Save product error: $e');
      return false;
    }
  }

  Future<bool> _saveService({
    required bool isEdit,
    String? docId,
    required String name,
    required double price,
    required String duration,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final payload = {
        'docId': docId,
        'name': name,
        'price': price,
        'duration': duration.isEmpty ? '1 hour' : duration,
        'description': description,
        'imageUrl': imageUrl,
      };

      final response = await http.post(
        Uri.parse('$kApiBaseUrl/catalog/services'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      debugPrint('Save service response: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Save service error: $e');
      return false;
    }
  }

  void _showAddEditServiceDialog({Map<String, dynamic>? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final priceController = TextEditingController(
      text: service?['price']?.toString() ?? '',
    );
    final durationController = TextEditingController(text: service?['duration'] ?? '1 hour');
    final descController = TextEditingController(text: service?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Service' : 'Add New Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name *',
                  hintText: 'e.g., Installation',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹) *',
                  hintText: 'e.g., 500 (0 for FREE)',
                  prefixText: '₹',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 2 hours',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the service...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter service name')),
                );
                return;
              }

              final serviceDocId = isEdit ? (service['docId'] ?? service['id']) : null;
              final serviceImageUrl = isEdit ? service['imageUrl'] : null;
              
              _saveService(
                isEdit: isEdit,
                docId: serviceDocId,
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0,
                duration: durationController.text,
                description: descController.text,
                imageUrl: serviceImageUrl,
              ).then((success) {
                if (success) {
                  Navigator.pop(ctx);
                  _loadData(); // Refresh from API
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Service updated!' : 'Service added!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save. Try again.')),
                  );
                }
              });
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Service'),
          ),
        ],
      ),
    );
  }
}
