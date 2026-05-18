import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../models/models.dart';
import '../models/sync_result.dart';
import 'notification_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final Connectivity _connectivity = Connectivity();
  final AuthService _auth = AuthService();
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Notification stream
  final _notificationController = StreamController<int>.broadcast();
  Stream<int> get notificationStream => _notificationController.stream;

  // API Configuration
  static const String _apiBaseUrl =
      'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod';
  static const String _adminApiUrl = '$_apiBaseUrl/admin';

  // Connection state
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // Initialize sync service
  Future<void> initialize() async {
    // Check initial connection
    await _checkConnection();

    // Listen for connection changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionState(result);
    });

    // Start periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncIfOnline();
    });
  }

  // Check current connection
  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionState(result);
  }

  // Update connection state
  void _updateConnectionState(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    // If we just came online, trigger sync
    if (!wasOnline && _isOnline) {
      syncIfOnline();
    }
  }

  // Specialized sync for orders only (faster)
  Future<SyncResult> syncOrdersOnly() async {
    if (_isSyncing) return SyncResult.alreadySyncing;
    if (!_isOnline) return SyncResult.offline;

    _isSyncing = true;
    try {
      final ordersResult = await _syncOrders();
      final bookingsResult = await _syncBookings();
      _isSyncing = false;
      return (ordersResult == SyncResult.success && bookingsResult == SyncResult.success) 
          ? SyncResult.success 
          : SyncResult.partial;
    } catch (e) {
      print('Sync orders only error: $e');
      _isSyncing = false;
      return SyncResult.failed;
    }
  }

  // Sync if online
  Future<void> syncIfOnline() async {
    if (_isOnline && !_isSyncing) {
      await syncAll();
    }
  }

  // Main sync method
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.alreadySyncing;
    if (!_isOnline) return SyncResult.offline;

    _isSyncing = true;
    final results = <SyncResult>[];

    try {
      final bool authenticated = _auth.isAuthenticated;

      // 1. Upload pending changes (only if authenticated)
      if (authenticated) {
        final uploadResult = await _uploadPendingChanges();
        print('Upload pending changes result: $uploadResult');
        results.add(uploadResult);
      }

      // 2. Download products (public)
      final productsResult = await _syncProducts();
      print('Products sync result: $productsResult');
      results.add(productsResult);

      // 3. Download services (public)
      final servicesResult = await _syncServices();
      print('Services sync result: $servicesResult');
      results.add(servicesResult);

      // 4. Download customers (authenticated)
      if (authenticated) {
        final customersResult = await _syncCustomers();
        print('Customers sync result: $customersResult');
        results.add(customersResult);
      }

      // 5. Download orders (authenticated)
      if (authenticated) {
        final ordersResult = await _syncOrders();
        print('Orders sync result: $ordersResult');
        results.add(ordersResult);
      }

      // 6. Download bookings (authenticated)
      if (authenticated) {
        final bookingsResult = await _syncBookings();
        print('Bookings sync result: $bookingsResult');
        results.add(bookingsResult);
      }

      // 7. Download Bills (authenticated)
      if (authenticated) {
        final billsResult = await _syncBills();
        print('Bills sync result: $billsResult');
        results.add(billsResult);
      }

      // 8. Sync Settings (public)
      await syncSettings();

      // 9. Update Notification Stats (only if authenticated)
      if (authenticated) {
        final metrics = await getRemoteMetrics();
        final localStats = await _db.getDashboardStats();
        
        final pendingOrders = metrics?['pendingOrders'] ?? localStats['pendingOrders'] ?? 0;
        final pendingBookings = metrics?['pendingBookings'] ?? localStats['pendingBookings'] ?? 0;
        _notificationController.add(pendingOrders + pendingBookings);
      }

      _isSyncing = false;

      print('All sync results: $results');
      print(
        'All success check: ${results.every((r) => r == SyncResult.success)}',
      );

      // Check if all succeeded
      if (results.isEmpty) {
        return SyncResult.success;
      } else if (results.every((r) => r == SyncResult.success)) {
        print('Returning SyncResult.success');
        return SyncResult.success;
      } else if (results.contains(SyncResult.partial)) {
        print('Returning SyncResult.partial');
        return SyncResult.partial;
      } else {
        print('Returning SyncResult.failed');
        return SyncResult.failed;
      }
    } catch (e) {
      print('Sync error: $e');
      _isSyncing = false;
      return SyncResult.failed;
    }
  }

  // Update booking status on server
  Future<SyncResult> updateBookingStatus(String bookingId, String status) async {
    if (!_isOnline) return SyncResult.offline;

    try {
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/bookings/$bookingId/status',
        method: 'PUT',
        body: {'status': status},
      );

      if (response.statusCode == 200) {
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Update booking status error: $e');
      return SyncResult.failed;
    }
  }

  // Update order status on server
  Future<SyncResult> updateOrderStatus(String orderId, String status) async {
    if (!_isOnline) return SyncResult.offline;

    try {
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/orders/$orderId/status',
        method: 'PUT',
        body: {'status': status},
      );

      if (response.statusCode == 200) {
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Update order status error: $e');
      return SyncResult.failed;
    }
  }

  // Upload pending changes from sync queue
  Future<SyncResult> _uploadPendingChanges() async {
    try {
      final queue = await _db.getSyncQueue();

      if (queue.isEmpty) return SyncResult.success;

      int successCount = 0;
      int failCount = 0;

      for (final item in queue) {
        try {
          final success = await _uploadItem(item);
          if (success) {
            await _db.clearSyncQueueItem(item['id']);
            await _db.markAsSynced(item['table_name'], item['record_id']);
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          print('Failed to upload item ${item['id']}: $e');
          failCount++;
        }
      }

      if (failCount == 0) return SyncResult.success;
      if (successCount == 0) return SyncResult.failed;
      return SyncResult.partial;
    } catch (e) {
      print('Upload pending changes error: $e');
      return SyncResult.failed;
    }
  }

  // Upload single item
  Future<bool> _uploadItem(Map<String, dynamic> item) async {
    final table = item['table_name'];
    final operation = item['operation'];
    final payload = jsonDecode(item['payload']);

    String endpoint;
    switch (table) {
      case 'bills':
        if (operation == 'update' || operation == 'delete') {
          endpoint = '$_adminApiUrl/bills/${payload['id'] ?? payload['docId']}';
        } else {
          endpoint = '$_adminApiUrl/bills';
        }
        break;
      case 'customers':
        if (operation == 'update') {
          endpoint = '$_adminApiUrl/users/${payload['id']}';
        } else {
          endpoint = '$_adminApiUrl/users';
        }
        break;
      case 'catalog':
        if (operation == 'delete') {
          endpoint = payload['type'] == 'product'
              ? '$_adminApiUrl/catalog/products/${payload['id']}'
              : '$_adminApiUrl/catalog/services/${payload['id']}';
        } else {
          endpoint = payload['type'] == 'product'
              ? '$_adminApiUrl/catalog/products'
              : '$_adminApiUrl/catalog/services';
        }
        break;
      case 'orders':
        // Check if this is a status update operation
        if (operation == 'update' && payload['status'] != null) {
          // Allow status updates (like confirmation) but use a different endpoint
          endpoint = '$_adminApiUrl/orders/${payload['id']}/status';
          // Status updates use PUT method
        } else {
          // Orders API is read-only for general uploads
          print('Skipping order upload - AWS orders API is read-only');
          return true;
        }
        break;
      case 'bookings':
        if (operation == 'update' && payload['status'] != null) {
          endpoint = '$_adminApiUrl/bookings/${payload['id']}/status';
        } else {
          print('Skipping booking upload - only status updates are supported');
          return true;
        }
        break;
      default:
        return false;
    }

    try {
      http.Response response;

      if (_auth.isAuthenticated) {
        // Use authenticated request
        if ((table == 'orders' || table == 'bookings') &&
            operation == 'update' &&
            payload['status'] != null) {
          // For order/booking status updates, use PUT method with status endpoint
          response = await _auth.makeAuthenticatedRequest(
            endpoint, // endpoint already includes the ID
            method: 'PUT',
            body: {'status': payload['status']},
          );
        } else if (table == 'bills' && operation == 'update') {
          response = await _auth.makeAuthenticatedRequest(
            endpoint,
            method: 'PUT',
            body: jsonDecode(item['payload']),
          );
        } else {
          // For other operations, use POST method
          if (operation == 'delete') {
            response = await _auth.makeAuthenticatedRequest(
              endpoint,
              method: 'DELETE',
            );
          } else {
            response = await _auth.makeAuthenticatedRequest(
              endpoint,
              method: 'POST',
              body: jsonDecode(item['payload']),
            );
          }
        }
      } else {
        // Fallback to unauthenticated request
        if ((table == 'orders' || table == 'bookings') &&
            operation == 'update' &&
            payload['status'] != null) {
          response = await http.put(
            Uri.parse(endpoint), // endpoint already includes the ID
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': payload['status']}),
          );
        } else if (table == 'bills' && operation == 'update') {
          response = await http.put(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: item['payload'],
          );
        } else {
          if (operation == 'delete') {
            response = await http.delete(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            response = await http.post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: item['payload'],
            );
          }
        }
      }

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      final bool isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && table == 'bills' && operation == 'insert') {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final serverItem = responseData['item'];
          if (serverItem != null) {
            final String newId = serverItem['id']?.toString() ?? '';
            final String newBillNumber = serverItem['billNumber']?.toString() ?? '';
            final String oldId = item['record_id']?.toString() ?? '';
            
            if (newId.isNotEmpty && newBillNumber.isNotEmpty && oldId.isNotEmpty) {
              print('Updating local SQLite bill oldId: $oldId -> newId: $newId, newBillNumber: $newBillNumber');
              await _db.updateLocalBillIdAndNumber(oldId, newId, newBillNumber);
            }
          }
        } catch (e) {
          print('Error updating local bill after upload: $e');
        }
      }

      return isSuccess;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  // Sync products from server
  Future<SyncResult> _syncProducts() async {
    try {
      final lastSync = await _db.getSetting('last_products_sync');
      final query = lastSync != null ? '?since=${Uri.encodeComponent(lastSync)}' : '';
      print('Syncing products from: $_apiBaseUrl/products$query');
      final response = await http.get(Uri.parse('$_apiBaseUrl/products$query'));
      print('Products response status: ${response.statusCode}');
      print(
        'Products response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} products');

        for (final item in data) {
          final catalogItem = CatalogItem(
            id: item['id'] ?? item['docId'],
            type: 'product',
            name: item['name'],
            price: double.tryParse(item['price'].toString()) ?? 0,
            gstPercent: double.tryParse(item['gstPercent']?.toString() ?? '18') ?? 18,
            category: item['category'],
            description: item['description'],
            imageUrl: item['imageUrl'],
            isActive: true,
            isSynced: true,
            updatedAt: DateTime.now(),
          );

          // Only update if not modified locally
          final existing = await _db.getCatalogItemById(catalogItem.id);
          if (existing == null || existing.isSynced) {
            await _db.insertCatalogItem(catalogItem, isSync: true);
          }
        }
        await _db.setSetting('last_products_sync', DateTime.now().toIso8601String());
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync products error: $e');
      return SyncResult.failed;
    }
  }

  // Sync services from server
  Future<SyncResult> _syncServices() async {
    try {
      final lastSync = await _db.getSetting('last_services_sync');
      final query = lastSync != null ? '?since=${Uri.encodeComponent(lastSync)}' : '';
      print('Syncing services from: $_apiBaseUrl/services$query');
      final response = await http.get(Uri.parse('$_apiBaseUrl/services$query'));
      print('Services response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} services');

        for (final item in data) {
          final catalogItem = CatalogItem(
            id: item['id'] ?? item['docId'],
            type: 'service',
            name: item['name'],
            price: double.tryParse(item['price'].toString()) ?? 0,
            gstPercent: double.tryParse(item['gstPercent']?.toString() ?? '18') ?? 18,
            category: item['category'],
            description: item['description'],
            imageUrl: item['imageUrl'],
            isActive: true,
            isSynced: true,
            updatedAt: DateTime.now(),
          );

          final existing = await _db.getCatalogItemById(catalogItem.id);
          if (existing == null || existing.isSynced) {
            await _db.insertCatalogItem(catalogItem, isSync: true);
          }
        }
        await _db.setSetting('last_services_sync', DateTime.now().toIso8601String());
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync services error: $e');
      return SyncResult.failed;
    }
  }

  // Sync customers from server
  Future<SyncResult> _syncCustomers() async {
    try {
      if (!_isOnline) return SyncResult.failed;
      
      print('Syncing customers from: $_adminApiUrl/users');
      final response = await http.get(Uri.parse('$_adminApiUrl/users'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} registered website users');
        
        int syncedCount = 0;
        for (final item in data) {
          final userId = item['id']?.toString();
          final rawPhone = item['phone']?.toString();
          
          if (rawPhone == null || rawPhone.isEmpty) {
            continue; // Need a phone number for local DB unique constraint
          }
          final phone = rawPhone.replaceAll(RegExp(r'\D'), '');
          
          final existingCustomer = await _db.getCustomerByPhone(phone);
          
          if (existingCustomer == null) {
            final customer = Customer(
              id: 'cust-$phone',
              name: item['name']?.toString() ?? 'Unknown User',
              phone: phone,
              email: item['email']?.toString(),
              source: 'website',
              address: item['address']?.toString(),
              createdAt: item['createdAt'] != null ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
              isSynced: true,
            );
            await _db.insertCustomer(customer, isSync: true);
            syncedCount++;
          } else {
            // Update existing if needed
            await _db.updateCustomer(existingCustomer.copyWith(
              email: item['email']?.toString() ?? existingCustomer.email,
              name: item['name']?.toString() ?? existingCustomer.name,
              source: 'website', // Ensure it's marked as website
            ), isSync: true);
          }
        }
        print('Successfully synced $syncedCount website users');
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync customers error: $e');
      return SyncResult.failed;
    }
  }

  // Fetch metrics from server
  Future<Map<String, dynamic>?> getRemoteMetrics({int days = 30}) async {
    try {
      if (!_isOnline) return null;
      
      print('Fetching metrics from: $_adminApiUrl/metrics?days=$days');
      final response = await http.get(Uri.parse('$_adminApiUrl/metrics?days=$days'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['item'] ?? responseData;
      }
      return null;
    } catch (e) {
      print('Error fetching metrics: $e');
      return null;
    }
  }

  // Sync orders from server
  Future<SyncResult> _syncOrders() async {
    try {
      print('Syncing orders from: $_adminApiUrl/orders');
      
      // Use authenticated request for admin endpoints
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/orders',
        method: 'GET',
      );

      print('Orders response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data =
            responseData['items'] ?? responseData['orders'] ?? [];
        print('Found ${data.length} orders');

        int syncedCount = 0;
        for (final item in data) {
          // Skip if no id
          final id = item['id']?.toString() ?? item['docId']?.toString();
          if (id == null || id.isEmpty) {
            print('Skipping order with null/empty id');
            continue;
          }

          // Use Order.fromMap to handle AWS format properly
          final order = Order.fromMap(item);

          // Check if new to trigger notification
          final db = await _db.database;
          final existing = await db.query('orders', where: 'id = ?', whereArgs: [order.id], limit: 1);
          if (existing.isEmpty && order.status == 'pending') {
            NotificationService().showNotification(
              id: order.id.hashCode,
              title: 'New Online Order!',
              body: 'You have received a new product order from ${order.customerName}.',
            );
          }

          await _db.insertOrder(order, isSync: true);
          syncedCount++;
          print('Synced order: $id - ${order.customerName}');

          // Also save customer from order data (since customers API doesn't exist)
          final customerData = item['customer'];
          final email = customerData is Map ? customerData['email']?.toString() : null;
          final userId = customerData is Map ? customerData['userId']?.toString() : item['userId']?.toString();
          
          print('Checking customer for order: ${order.customerName} - Phone: ${order.customerPhone} - Email: $email - UserId: $userId');
          
          if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
            final existingCustomer = await _db.getCustomerByPhone(order.customerPhone!);
            
            // Only auto-create if not exists OR if we now have an email/userId for an existing one
            if (existingCustomer == null) {
              // Only auto-create "Website" customers if they have a userId (Cognito accounts)
              // Others will stay as part of the order but won't clutter the Customers list 
              // unless they are manually added as Walk-in.
              if (userId != null && userId.isNotEmpty) {
                final customer = Customer(
                  id: 'cust-${order.customerPhone}',
                  name: order.customerName,
                  phone: order.customerPhone,
                  email: email,
                  source: 'website',
                  address: order.customerAddress,
                  createdAt: DateTime.now(),
                  isSynced: true,
                );
                await _db.insertCustomer(customer, isSync: true);
                print('Added Website customer from order: ${customer.name}');
              }
            } else {
              // If exists, ensure it's marked as website if it has a userId
              if (userId != null && userId.isNotEmpty && existingCustomer.source != 'website') {
                await _db.updateCustomer(existingCustomer.copyWith(email: email ?? existingCustomer.email, source: 'website'), isSync: true);
              }
            }
          }
        }
        print('Successfully synced $syncedCount orders');
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync orders error: $e');
      return SyncResult.failed;
    }
  }

  // Manual trigger sync from UI
  Future<SyncResult> manualSync() async {
    return await syncAll();
  }

  // Call this after any local save to sync immediately if online
  Future<SyncResult> syncOnSave() async {
    if (_isOnline && !_isSyncing) {
      print('Auto-sync triggered after local save...');
      // Small delay to let UI update first
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await syncAll();
      print('Auto-sync completed: ${result.message}');
      return result;
    } else if (!_isOnline) {
      print('Device offline - changes queued for next sync');
      return SyncResult.offline;
    } else {
      print('Sync already in progress - changes queued');
      return SyncResult.alreadySyncing;
    }
  }

  // Sync bookings from server
  Future<SyncResult> _syncBookings() async {
    try {
      if (!_isOnline) return SyncResult.offline;

      print('Syncing bookings from: $_adminApiUrl/bookings');
      
      // Use authenticated request for admin endpoints
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/bookings',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? 
                                   responseData['bookings'] ?? 
                                   responseData['item'] ?? [];
        print('Found ${data.length} bookings from server');

        for (final item in data) {
          try {
            final booking = Booking.fromMap(item);
            
            // Check if new to trigger notification
            final db = await _db.database;
            final existing = await db.query('bookings', where: 'id = ?', whereArgs: [booking.id], limit: 1);
            if (existing.isEmpty && (booking.status == 'pending' || booking.status == 'scheduled')) {
              NotificationService().showNotification(
                id: booking.id.hashCode,
                title: 'New Service Booking!',
                body: '${booking.name} requested a ${booking.serviceType} service.',
              );
            }

            await _db.insertBooking(booking);
            print('Synced booking: ${booking.id} - ${booking.name} - Status: ${booking.status}');
          } catch (e) {
            print('Error parsing booking: $e - Data: $item');
          }
        }

        return SyncResult.success;
      } else {
        print('Bookings sync failed with status: ${response.statusCode}');
        return SyncResult.failed;
      }
    } catch (e) {
      print('Sync bookings error: $e');
      return SyncResult.failed;
    }
  }

  // Sync bills from server
  Future<SyncResult> _syncBills() async {
    try {
      if (!_isOnline) return SyncResult.offline;

      print('Syncing bills from: $_adminApiUrl/bills');
      
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/bills',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} bills from server');

        for (final item in data) {
          try {
            final bill = Bill.fromMap(item);
            await _db.insertBill(bill, isSync: true);
          } catch (e) {
            print('Error parsing bill: $e - Data: $item');
          }
        }
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync bills error: $e');
      return SyncResult.failed;
    }
  }

  // Sync business and billing settings from server
  Future<void> syncSettings() async {
    try {
      if (!_isOnline) return;

      // Business Settings
      final bizResponse = await http.get(Uri.parse('$_apiBaseUrl/settings/business'));
      if (bizResponse.statusCode == 200) {
        final data = jsonDecode(bizResponse.body)['item'];
        if (data != null) {
          if (data['companyName'] != null) await _db.setSetting('companyName', data['companyName'].toString());
          if (data['supportPhone'] != null) await _db.setSetting('supportPhone', data['supportPhone'].toString());
          if (data['supportEmail'] != null) await _db.setSetting('supportEmail', data['supportEmail'].toString());
          if (data['locality'] != null) await _db.setSetting('locality', data['locality'].toString());
          if (data['addressLine1'] != null) await _db.setSetting('address', data['addressLine1'].toString());
          if (data['addressLine2'] != null) await _db.setSetting('addressLine2', data['addressLine2'].toString());
          if (data['addressLine3'] != null) await _db.setSetting('addressLine3', data['addressLine3'].toString());
          if (data['gstin'] != null) await _db.setSetting('gstin', data['gstin'].toString());
        }
      }

      // Billing Settings
      final billResponse = await http.get(Uri.parse('$_apiBaseUrl/settings/billing'));
      if (billResponse.statusCode == 200) {
        final data = jsonDecode(billResponse.body)['item'];
        if (data != null) {
          if (data['invoicePrefix'] != null) await _db.setSetting('invoicePrefix', data['invoicePrefix'].toString());
          if (data['gstRate'] != null) {
            final rate = (double.tryParse(data['gstRate'].toString()) ?? 0) * 100;
            await _db.setSetting('defaultGstRate', rate.toInt().toString());
          }
          if (data['gstEnabled'] != null) await _db.setSetting('gstEnabled', data['gstEnabled'].toString());
        }
      }
    } catch (e) {
      print('Error syncing settings: $e');
    }
  }

  // Upload current settings to server
  Future<SyncResult> uploadSettings() async {
    if (!_isOnline) return SyncResult.offline;

    try {
      // 1. Prepare Business Settings Payload
      final bizData = {
        'companyName': await _db.getSetting('companyName') ?? 'A1 Water Tech',
        'supportPhone': await _db.getSetting('supportPhone') ?? '',
        'supportEmail': await _db.getSetting('supportEmail') ?? '',
        'locality': await _db.getSetting('locality') ?? '',
        'addressLine1': await _db.getSetting('address') ?? '',
        'addressLine2': await _db.getSetting('addressLine2') ?? '',
        'addressLine3': await _db.getSetting('addressLine3') ?? '',
        'gstin': await _db.getSetting('gstin') ?? '',
      };

      // 2. Prepare Billing Settings Payload
      final gstRateStr = await _db.getSetting('defaultGstRate') ?? '18';
      final gstEnabledStr = await _db.getSetting('gstEnabled') ?? 'true';
      
      final billData = {
        'companyName': bizData['companyName'],
        'supportPhone': bizData['supportPhone'],
        'invoicePrefix': await _db.getSetting('invoicePrefix') ?? 'BILL',
        'gstRate': (double.tryParse(gstRateStr) ?? 18) / 100,
        'gstEnabled': gstEnabledStr == 'true',
      };

      // 3. Upload to Admin Endpoints
      final bizResp = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/settings/business',
        method: 'PUT',
        body: bizData,
      );

      final billResp = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/settings/billing',
        method: 'PUT',
        body: billData,
      );

      if (bizResp.statusCode == 200 && billResp.statusCode == 200) {
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Error uploading settings: $e');
      return SyncResult.failed;
    }
  }

  // Dispose
  void dispose() {
    _syncTimer?.cancel();
  }
}

