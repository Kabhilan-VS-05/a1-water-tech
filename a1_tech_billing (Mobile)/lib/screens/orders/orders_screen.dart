import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../models/sync_result.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  late TabController _tabController;
  List<Order> _orders = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isFirstLoad = true;
  String _selectedFilter = 'pending';
  String _selectedType = 'service'; // 'service' or 'product'
  Timer? _refreshTimer;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  @override
  void initState() {
    super.initState();
    // Initialize TabController and sync its index with AppProvider
    _tabController = TabController(length: 3, vsync: this);
    // Ensure AppProvider knows the initial tab (pending) - wrapped in microtask to avoid build error
    Future.microtask(() {
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false).setOrdersTabIndex(0);
      }
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        setState(() {
          _selectedFilter = ['pending', 'confirmed', 'rejected'][newIndex];
        });
        // Update provider so it knows the current orders tab index
        Provider.of<AppProvider>(context, listen: false).setOrdersTabIndex(newIndex);
      }
    });
    _loadOrders();
    
    // Auto-refresh orders every 10 seconds while on this screen
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _backgroundSync();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _db.getOrders();
      final bookings = await _db.getBookings();
      setState(() {
        _orders = orders;
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load orders error: $e');
      setState(() {
        _isLoading = false;
      });
    }
    _backgroundSync();
  }

  Future<void> _manualSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    try {
      await _sync.syncOrdersOnly();
    } catch (e) {
      debugPrint('Manual sync error: $e');
    }
    await _refreshOrders();
    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _backgroundSync() async {
    final bool showLoader = _isFirstLoad;
    if (showLoader && mounted) {
      setState(() {
        _isSyncing = true;
        _isFirstLoad = false;
      });
    }
    try {
      // Use faster order-only sync
      await _sync.syncOrdersOnly();
      await _refreshOrders();
    } catch (e) {
      debugPrint('Background sync error: $e');
    } finally {
      if (showLoader && mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _refreshOrders() async {
    final freshOrders = await _db.getOrders();
    final freshBookings = await _db.getBookings();
    if (mounted) {
      setState(() {
        _orders = freshOrders;
        _bookings = freshBookings;
      });
    }
  }

  bool _isBookingExpired(Booking b) {
    if (b.status == 'completed' || b.status == 'cancelled' || b.status == 'rejected') return false;
    try {
      if (b.date == null || b.slot == null) return false;
      final endHourStr = b.slot!.split('-')[1].trim().split(':')[0];
      final endHour = int.parse(endHourStr);
      final bookingDate = b.date!;
      final endDateTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, endHour);
      return endDateTime.isBefore(DateTime.now());
    } catch (e) {
      if (b.date == null) return false;
      final bookingDate = b.date!;
      final endDateTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, 23, 59, 59);
      return endDateTime.isBefore(DateTime.now());
    }
  }

  List<dynamic> get _filteredItems {
    List<dynamic> items = [];
    if (_selectedType == 'product') {
      switch (_selectedFilter) {
        case 'pending':
          items = _orders.where((o) => o.status == 'pending').toList();
          break;
        case 'confirmed':
          items = _orders.where((o) => o.status == 'confirmed' || o.status == 'completed').toList();
          break;
        case 'rejected':
          items = _orders.where((o) => o.status == 'rejected').toList();
          break;
        default:
          items = _orders;
      }
    } else {
      switch (_selectedFilter) {
        case 'pending':
          items = _bookings.where((b) => (b.status == 'pending' || b.status == 'scheduled') && !_isBookingExpired(b)).toList();
          break;
        case 'confirmed':
          items = _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed').toList();
          break;
        case 'rejected':
          items = _bookings.where((b) => b.status == 'rejected' || ((b.status == 'pending' || b.status == 'scheduled') && _isBookingExpired(b))).toList();
          break;
        default:
          items = _bookings;
      }
    }

    // Apply Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        if (item is Order) {
          final matchesBasic = item.id.toLowerCase().contains(query) ||
              item.customerName.toLowerCase().contains(query) ||
              (item.customerPhone?.toLowerCase().contains(query) ?? false) ||
              (item.customerAddress?.toLowerCase().contains(query) ?? false);
          
          final matchesItems = item.items.any((orderItem) =>
              orderItem.name.toLowerCase().contains(query) ||
              orderItem.type.toLowerCase().contains(query) ||
              (orderItem.hsn?.toLowerCase().contains(query) ?? false));
              
          return matchesBasic || matchesItems;
        } else if (item is Booking) {
          final matchesBasic = item.id.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query) ||
              item.phone.toLowerCase().contains(query) ||
              (item.address?.toLowerCase().contains(query) ?? false) ||
              item.serviceType.toLowerCase().contains(query);
          return matchesBasic;
        }
        return false;
      }).toList();
    }

    // Apply Date Range Filter
    if (_selectedDateRange != null) {
      items = items.where((item) {
        DateTime? date;
        if (item is Order) {
          date = item.orderDate;
        } else if (item is Booking) {
          date = item.date;
        }
        if (date == null) return true;
        
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    return items;
  }

  Future<void> _updateBookingStatus(Booking booking, String status) async {
    // 1. Update locally
    await _db.updateBookingStatus(booking.id, status);
    
    // 2. Update remotely
    final result = await _sync.updateBookingStatus(booking.id, status);
    
    if (result != SyncResult.success) {
      debugPrint('Remote booking status update failed: $result');
    }

    await _loadOrders();
    _showStatusSnackBar(status);
  }

  Future<void> _updateOrderStatus(Order order, String status) async {
    // 1. Update locally
    await _db.updateOrderStatus(order.id, status);
    
    // 2. Update remotely
    final result = await _sync.updateOrderStatus(order.id, status);
    
    if (result != SyncResult.success) {
      debugPrint('Remote order status update failed: $result');
    }

    await _loadOrders();
    _showStatusSnackBar(status);
  }

  void _showStatusSnackBar(String status) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as $status'),
          backgroundColor: status == 'confirmed' ? AppTheme.secondaryColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _generateBill(Order order) async {
    Navigator.pushNamed(context, '/billing/auto', arguments: order);
  }

  Future<void> _generateBillFromBooking(Booking booking) async {
    // Show a loading dialog during conversion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // 1. Fetch catalog items of type 'service' to find the price
      final services = await _db.getCatalogItems(type: 'service');
      
      // Find the matching service item
      CatalogItem? matchedService;
      for (var service in services) {
        if (service.name.toLowerCase() == booking.serviceType.toLowerCase()) {
          matchedService = service;
          break;
        }
      }
      
      // Default fallback if not found in catalog
      final itemId = matchedService?.id ?? 'SVC-GEN';
      final serviceName = matchedService?.name ?? booking.serviceType;
      final price = matchedService?.price ?? 299.0; // Fallback price
      final gstPercent = matchedService?.gstPercent ?? 18.0;
      final imageUrl = matchedService?.imageUrl;

      final double totalWithoutGst = price * 1;
      final double gstAmount = (totalWithoutGst * gstPercent) / 100;
      final double totalWithGst = totalWithoutGst + gstAmount;

      final orderItem = OrderItem(
        itemId: itemId,
        name: serviceName,
        type: 'service',
        price: price,
        quantity: 1,
        gstPercent: gstPercent,
        hsn: matchedService?.hsn,
        imageUrl: imageUrl,
      );

      final order = Order(
        id: 'ORDER-SVC-${booking.id}',
        orderId: 'SVC-${booking.id.length > 6 ? booking.id.substring(0, 6).toUpperCase() : booking.id.toUpperCase()}',
        customerName: booking.name,
        customerPhone: booking.phone,
        customerAddress: booking.address,
        items: [orderItem],
        subtotal: totalWithoutGst,
        gstAmount: gstAmount,
        total: totalWithGst,
        status: 'confirmed',
        orderDate: booking.date ?? booking.createdAt,
      );

      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushNamed(context, '/billing/auto', arguments: order).then((_) {
          // Reload orders/bookings in case they were completed
          _loadOrders();
        });
      }
    } catch (e) {
      // Pop loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bill: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    
    // Sync tab controller if index mismatch
    if (_tabController.index != appProvider.ordersTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != appProvider.ordersTabIndex) {
          _tabController.animateTo(appProvider.ordersTabIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondaryLight,
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isSyncing)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    minHeight: 2.5,
                  ),
                _buildSearchAndFilterRow(),
                _buildTypeSelector(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _manualSync,
                    child: _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            itemCount: _filteredItems.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (ctx, index) {
                              final item = _filteredItems[index];
                              if (item is Order) {
                                return _PremiumOrderCard(
                                  order: item,
                                  onConfirm: () => _updateOrderStatus(item, 'confirmed'),
                                  onReject: () => _updateOrderStatus(item, 'rejected'),
                                  onGenerateBill: () => _generateBill(item),
                                );
                              } else if (item is Booking) {
                                return _PremiumBookingCard(
                                  booking: item,
                                  onConfirm: () => _updateBookingStatus(item, 'confirmed'),
                                  onReject: () => _updateBookingStatus(item, 'rejected'),
                                  onGenerateBill: () => _generateBillFromBooking(item),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                      hintText: 'Search by client, ID, item...',
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

  Widget _buildTypeSelector() {
    int ordersCount = 0;
    int bookingsCount = 0;

    switch (_selectedFilter) {
      case 'pending':
        ordersCount = _orders.where((o) => o.status == 'pending').length;
        bookingsCount = _bookings.where((b) => (b.status == 'pending' || b.status == 'scheduled') && !_isBookingExpired(b)).length;
        break;
      case 'confirmed':
        ordersCount = _orders.where((o) => o.status == 'confirmed' || o.status == 'completed').length;
        bookingsCount = _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed').length;
        break;
      case 'rejected':
        ordersCount = _orders.where((o) => o.status == 'rejected').length;
        bookingsCount = _bookings.where((b) => b.status == 'rejected' || ((b.status == 'pending' || b.status == 'scheduled') && _isBookingExpired(b))).length;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          _TypeButton(
            title: 'Service Bookings ($bookingsCount)',
            isSelected: _selectedType == 'service',
            icon: Icons.miscellaneous_services_outlined,
            onTap: () => setState(() => _selectedType = 'service'),
          ),
          const SizedBox(width: 12),
          _TypeButton(
            title: 'Product Orders ($ordersCount)',
            isSelected: _selectedType == 'product',
            icon: Icons.shopping_bag_outlined,
            onTap: () => setState(() => _selectedType = 'product'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: AppTheme.dividerColorLight),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedType == 'product' ? 'orders' : 'bookings'} in this category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.accentColor : AppTheme.dividerColorLight,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.accentColor : AppTheme.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.accentColor : AppTheme.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onGenerateBill;

  const _PremiumOrderCard({
    required this.order,
    required this.onConfirm,
    required this.onReject,
    required this.onGenerateBill,
  });

  @override
  State<_PremiumOrderCard> createState() => _PremiumOrderCardState();
}

class _PremiumOrderCardState extends State<_PremiumOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);
    final dateFormatted = DateFormat('MMM d, yyyy • h:mm a').format(widget.order.orderDate!);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.order.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(dateFormatted, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Customer Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            child: Text(
                              widget.order.customerName.isNotEmpty ? widget.order.customerName[0].toUpperCase() : 'C',
                              style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (widget.order.customerPhone != null)
                                  Text(widget.order.customerPhone!, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${widget.order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accentColor)),
                              Text('${widget.order.items.length} items', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      
                      // Expand/Collapse Details
                      if (_isExpanded) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Order Items', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...widget.order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.quantity}x ${item.name}', style: Theme.of(context).textTheme.bodyMedium)),
                              Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        )),
                        const SizedBox(height: 8),
                        if (widget.order.customerAddress != null) ...[
                          Text('Address', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(widget.order.customerAddress!, style: Theme.of(context).textTheme.bodyMedium),
                        ]
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() => _isExpanded = !_isExpanded),
                            icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
                            label: Text(_isExpanded ? 'Less details' : 'More details'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondaryLight),
                          ),
                          
                          if (widget.order.status == 'pending') ...[
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: widget.onReject,
                                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: widget.onConfirm,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          ] else if (widget.order.status == 'confirmed' || widget.order.status == 'completed') ...[
                            ElevatedButton.icon(
                              onPressed: widget.onGenerateBill,
                              icon: const Icon(Icons.receipt_long_rounded, size: 18),
                              label: Text(widget.order.status == 'completed' ? 'Regenerate Bill' : 'Generate Bill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.order.status == 'completed' ? Colors.grey.shade700 : AppTheme.accentColor,
                              ),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'confirmed': return AppTheme.secondaryColor;
      case 'completed': return AppTheme.secondaryColor;
      case 'rejected': return AppTheme.errorColor;
      default: return AppTheme.textSecondaryLight;
    }
  }
}

class _PremiumBookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onGenerateBill;

  const _PremiumBookingCard({
    required this.booking,
    required this.onConfirm,
    required this.onReject,
    required this.onGenerateBill,
  });

  @override
  State<_PremiumBookingCard> createState() => _PremiumBookingCardState();
}

class _PremiumBookingCardState extends State<_PremiumBookingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.booking.status);
    final dateFormatted = widget.booking.date != null 
        ? DateFormat('EEE, MMM d, y').format(widget.booking.date!)
        : 'Date not set';
    final createdAtFormatted = DateFormat('MMM d, h:mm a').format(widget.booking.createdAt);

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.booking.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(createdAtFormatted, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Text(
                      widget.booking.name.isNotEmpty ? widget.booking.name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.booking.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.booking.phone, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Service',
                      style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Booking Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(Icons.settings_outlined, 'Service Type', widget.booking.serviceType),
                  ),
                  Expanded(
                    child: _buildInfoItem(Icons.calendar_today_outlined, 'Requested Date', dateFormatted),
                  ),
                ],
              ),
              
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                if (widget.booking.slot != null)
                  _buildInfoItem(Icons.access_time, 'Time Slot', widget.booking.slot!),
                const SizedBox(height: 12),
                if (widget.booking.address != null)
                  _buildInfoItem(Icons.location_on_outlined, 'Address', widget.booking.address!),
                const SizedBox(height: 12),
                if (widget.booking.email != null)
                  _buildInfoItem(Icons.email_outlined, 'Email', widget.booking.email!),
              ],
              
              const SizedBox(height: 20),
              
              // Actions
              if (widget.booking.status == 'pending' || widget.booking.status == 'scheduled')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                )
              else if (widget.booking.status == 'confirmed' || widget.booking.status == 'completed')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onGenerateBill,
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text(widget.booking.status == 'completed' ? 'Regenerate Bill' : 'Generate Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.booking.status == 'completed' ? Colors.grey.shade700 : AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryLight),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 10)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
