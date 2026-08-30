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
  Timer? _quickSyncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _initialized = false;
  DateTime? _lastQuickSyncAt;
  
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
    if (_initialized) return;
    _initialized = true;

    // Check initial connection
    await _checkConnection();

    // Listen for connection changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionState(result);
    });

    // Start periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncIfOnline();
    });

    // Start high-frequency check for new orders/bookings in foreground.
    _quickSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      await _triggerQuickSync();
    });

    // Immediate startup checks in background so UI renders instantly without blocking.
    syncIfOnline();
    _triggerQuickSync();
  }

  Future<void> _triggerQuickSync() async {
    if (!_isOnline || _isSyncing || !_auth.isAuthenticated) return;

    final now = DateTime.now();
    if (_lastQuickSyncAt != null &&
        now.difference(_lastQuickSyncAt!) < const Duration(seconds: 6)) {
      return;
    }

    _lastQuickSyncAt = now;
    await syncOrdersOnly();
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

  // Instant trigger for freshly created bills, quotations, or orders
  Future<SyncResult> syncOnSave() async {
    if (_isOnline) {
      return await syncAll();
    }
    return SyncResult.offline;
  }

  // Main sync method
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.alreadySyncing;
    if (!_isOnline) return SyncResult.offline;

    _isSyncing = true;
    final results = <SyncResult>[];

    try {
      final bool authenticated = _auth.isAuthenticated;

      // 1. Upload pending changes (always upload unsynced items)
      final uploadResult = await _uploadPendingChanges();
      print('Upload pending changes result: $uploadResult');
      results.add(uploadResult);

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

      // 7.5. Download Quotations (authenticated)
      if (authenticated) {
        final quotationsResult = await _syncQuotations();
        print('Quotations sync result: $quotationsResult');
        results.add(quotationsResult);
      }

      // 7.6. Download Purchase Orders (authenticated)
      if (authenticated) {
        final poResult = await _syncPurchaseOrders();
        print('Purchase Orders sync result: $poResult');
        results.add(poResult);
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
      // Force-backfill old/local bills & quotations that are not yet synced
      final forceBillsResult = await _forceUploadUnsyncedBills();
      if (forceBillsResult == SyncResult.failed) {
        print('Force upload unsynced bills failed.');
      }

      final forceQuotationsResult = await _forceUploadUnsyncedQuotations();
      if (forceQuotationsResult == SyncResult.failed) {
        print('Force upload unsynced quotations failed.');
      }

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

  Future<SyncResult> _forceUploadUnsyncedBills() async {
    if (!_isOnline) return SyncResult.offline;

    try {
      final unsyncedBills = await _db.getUnsyncedBills();
      if (unsyncedBills.isEmpty) return SyncResult.success;

      int successCount = 0;
      int failCount = 0;

      for (final bill in unsyncedBills) {
        try {
          final isServerId = int.tryParse(bill.id) != null;
          if (isServerId && bill.billNumber.isNotEmpty) {
            await _db.markBillAsSynced(bill.id);
            successCount++;
            continue;
          }

          final payload = {
            'id': bill.id,
            'billNumber': bill.billNumber,
            'customerId': bill.customerId,
            'customerName': bill.customerName,
            'customerPhone': bill.customerPhone,
            'customerAddress': bill.customerAddress,
            'customer': {
              'name': bill.customerName,
              'phone': bill.customerPhone,
              'address': bill.customerAddress,
            },
            'items': bill.items.map((i) => i.toMap()).toList(),
            'subtotal': bill.subtotal,
            'gstAmount': bill.gstAmount,
            'total': bill.total,
            'status': bill.status,
            'paymentMode': bill.paymentMode,
            'createdAt': bill.createdAt.toIso8601String(),
          };

          http.Response response;
          if (_auth.isAuthenticated) {
            response = await _auth.makeAuthenticatedRequest(
              '$_adminApiUrl/bills',
              method: 'POST',
              body: payload,
            );
          } else {
            response = await http.post(
              Uri.parse('$_adminApiUrl/bills'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final serverItem = responseData['item'];
            final String newId = serverItem?['id']?.toString() ?? '';
            final String newBillNumber = serverItem?['billNumber']?.toString() ?? '';

            if (newId.isNotEmpty && newBillNumber.isNotEmpty) {
              await _db.updateLocalBillIdAndNumber(bill.id, newId, newBillNumber);
            }
            await _db.markBillAsSynced(newId.isNotEmpty ? newId : bill.id);
            successCount++;
          } else {
            print('Force bill upload failed (${bill.id}): ${response.statusCode} ${response.body}');
            failCount++;
          }
        } catch (e) {
          print('Force bill upload error (${bill.id}): $e');
          failCount++;
        }
      }

      if (failCount == 0) return SyncResult.success;
      if (successCount == 0) return SyncResult.failed;
      return SyncResult.partial;
    } catch (e) {
      print('Force upload unsynced bills error: $e');
      return SyncResult.failed;
    }
  }

  Future<SyncResult> _forceUploadUnsyncedQuotations() async {
    if (!_isOnline) return SyncResult.offline;

    try {
      final unsyncedQuotations = await _db.getUnsyncedQuotations();
      if (unsyncedQuotations.isEmpty) return SyncResult.success;

      int successCount = 0;
      int failCount = 0;

      for (final quotation in unsyncedQuotations) {
        try {
          final isServerId = int.tryParse(quotation.id) != null;
          if (isServerId && quotation.quotationNumber.isNotEmpty) {
            await _db.markQuotationAsSynced(quotation.id);
            successCount++;
            continue;
          }

          final payload = quotation.toMap();
          payload['items'] = quotation.items.map((i) => i.toMap()).toList();

          http.Response response;
          if (_auth.isAuthenticated) {
            response = await _auth.makeAuthenticatedRequest(
              '$_adminApiUrl/quotations',
              method: 'POST',
              body: payload,
            );
          } else {
            response = await http.post(
              Uri.parse('$_adminApiUrl/quotations'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final serverItem = responseData['item'];
            final String newId = serverItem?['id']?.toString() ?? '';
            final String newQuotationNumber = serverItem?['quotationNumber']?.toString() ?? '';

            if (newId.isNotEmpty && newQuotationNumber.isNotEmpty) {
              await _db.updateLocalQuotationIdAndNumber(quotation.id, newId, newQuotationNumber);
            }
            await _db.markQuotationAsSynced(newId.isNotEmpty ? newId : quotation.id);
            successCount++;
          } else {
            print('Force quotation upload failed (${quotation.id}): ${response.statusCode} ${response.body}');
            failCount++;
          }
        } catch (e) {
          print('Force quotation upload error (${quotation.id}): $e');
          failCount++;
        }
      }

      if (failCount == 0) return SyncResult.success;
      if (successCount == 0) return SyncResult.failed;
      return SyncResult.partial;
    } catch (e) {
      print('Force upload unsynced quotations error: $e');
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
      case 'quotations':
        if (operation == 'update' || operation == 'delete') {
          endpoint = '$_adminApiUrl/quotations/${payload['id'] ?? item['record_id']}';
        } else {
          endpoint = '$_adminApiUrl/quotations';
        }
        break;
      case 'purchase_orders':
        if (operation == 'update' || operation == 'delete') {
          endpoint = '$_adminApiUrl/purchase-orders/${payload['id'] ?? item['record_id']}';
        } else {
          endpoint = '$_adminApiUrl/purchase-orders';
        }
        break;
      case 'customers':
        if (operation == 'update' || operation == 'delete') {
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

    Map<String, dynamic> requestBody = Map<String, dynamic>.from(payload);
    if ((table == 'bills' || table == 'quotations' || table == 'purchase_orders') && requestBody['items'] is String) {
      try {
        requestBody['items'] = jsonDecode(requestBody['items'] as String);
      } catch (_) {}
    }

    try {
      http.Response response;

      if (_auth.isAuthenticated) {
        // Use authenticated request
        if ((table == 'orders' || table == 'bookings' || table == 'quotations' || table == 'purchase_orders') &&
            operation == 'update' &&
            payload['status'] != null) {
          // For status updates, use PUT method
          response = await _auth.makeAuthenticatedRequest(
            endpoint, // endpoint already includes the ID
            method: 'PUT',
            body: {'status': payload['status']},
          );
        } else if ((table == 'bills' || table == 'quotations' || table == 'purchase_orders') && operation == 'update') {
          response = await _auth.makeAuthenticatedRequest(
            endpoint,
            method: 'PUT',
            body: requestBody,
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
              body: requestBody,
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
            body: jsonEncode(requestBody),
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
              body: jsonEncode(requestBody),
            );
          }
        }
      }

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      final bool isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && (table == 'bills' || table == 'quotations' || table == 'purchase_orders')) {
        final String oldId = item['record_id']?.toString() ?? payload['id']?.toString() ?? '';
        String targetId = oldId;

        if (operation == 'insert') {
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final serverItem = responseData['item'];
            if (serverItem != null) {
              final String newId = serverItem['id']?.toString() ?? '';
              final String newNumber = serverItem['billNumber']?.toString() ?? 
                                       serverItem['quotationNumber']?.toString() ?? 
                                       serverItem['poNumber']?.toString() ?? '';
              
              if (newId.isNotEmpty && newNumber.isNotEmpty && oldId.isNotEmpty && oldId != newId) {
                print('Updating local SQLite $table oldId: $oldId -> newId: $newId, newNumber: $newNumber');
                if (table == 'bills') {
                  await _db.updateLocalBillIdAndNumber(oldId, newId, newNumber);
                } else if (table == 'quotations') {
                  await _db.updateLocalQuotationIdAndNumber(oldId, newId, newNumber);
                } else if (table == 'purchase_orders') {
                  await _db.updateLocalPurchaseOrderIdAndNumber(oldId, newId, newNumber);
                }
                targetId = newId;
              }
            }
          } catch (e) {
            print('Error updating local $table after upload: $e');
          }
        }

        if (targetId.isNotEmpty) {
          print('Marking $table as synced: $targetId');
          if (table == 'bills') {
            await _db.markBillAsSynced(targetId);
          } else if (table == 'quotations') {
            await _db.markQuotationAsSynced(targetId);
          } else if (table == 'purchase_orders') {
            await _db.markPurchaseOrderAsSynced(targetId);
          }
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
            hsn: item['hsn'],
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
            hsn: item['hsn'],
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
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/users',
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} registered website users');
        
        int syncedCount = 0;
        for (final item in data) {
          final rawId = item['id']?.toString();
          final rawPhone = item['phone']?.toString();
          final source = item['source']?.toString() ?? 'website';
          
          final String? phone = (rawPhone != null && rawPhone.isNotEmpty)
              ? rawPhone.replaceAll(RegExp(r'\D'), '')
              : null;
          
          final customerId = rawId ?? (phone != null ? 'cust-$phone' : 'cust-${item['name']}');

          final existingCustomer = await _db.getCustomerById(customerId) ?? 
              (phone != null ? await _db.getCustomerByPhone(phone) : null);
          
          if (existingCustomer == null) {
            final customer = Customer(
              id: customerId,
              name: item['name']?.toString() ?? 'Registered Client',
              phone: phone,
              email: item['email']?.toString(),
              source: source == 'manual' ? 'manual' : 'website',
              address: item['address']?.toString(),
              totalVisits: int.tryParse(item['totalVisits']?.toString() ?? '0') ?? 0,
              totalSpent: double.tryParse(item['totalSpent']?.toString() ?? '0.0') ?? 0.0,
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
              source: source == 'manual' ? 'manual' : 'website',
              address: item['address']?.toString() ?? existingCustomer.address,
              totalVisits: int.tryParse(item['totalVisits']?.toString() ?? '0') ?? existingCustomer.totalVisits,
              totalSpent: double.tryParse(item['totalSpent']?.toString() ?? '0.0') ?? existingCustomer.totalSpent,
              isSynced: true,
            ), isSync: true);
          }
        }
        print('Successfully synced $syncedCount users');
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
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/metrics?days=$days',
        method: 'GET',
      );
      
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
              payload: 'orders',
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
          
          if (order.customerName.isNotEmpty) {
            final String? phone = (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                ? order.customerPhone!.replaceAll(RegExp(r'\D'), '')
                : null;
            final custId = phone != null ? 'cust-$phone' : 'cust-order-${order.id}';

            final existingCustomer = (phone != null ? await _db.getCustomerByPhone(phone) : null) ??
                await _db.getCustomerById(custId);

            if (existingCustomer == null) {
              final customer = Customer(
                id: custId,
                name: order.customerName,
                phone: phone,
                email: email,
                source: 'website',
                address: order.customerAddress,
                createdAt: order.orderDate,
                isSynced: true,
              );
              await _db.insertCustomer(customer, isSync: true);
              print('Added Online Client from order: ${customer.name}');
            } else {
              if (existingCustomer.source != 'website') {
                await _db.updateCustomer(existingCustomer.copyWith(
                  email: email ?? existingCustomer.email,
                  source: 'website',
                ), isSync: true);
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

  Future<SyncResult> forceSyncAllBillsToCloud() async {
    if (!_isOnline) return SyncResult.offline;

    final upload = await _forceUploadUnsyncedBills();
    final pull = await _syncBills();

    // Auto-heal: ensure all bills downloaded or formatted with server bill number are marked as synced
    try {
      final allBills = await _db.getBills();
      for (final bill in allBills) {
        if (!bill.isSynced && (bill.billNumber.startsWith('BILL-') || int.tryParse(bill.id) != null)) {
          await _db.markBillAsSynced(bill.id);
        }
      }
    } catch (_) {}

    if (upload == SyncResult.success && pull == SyncResult.success) {
      return SyncResult.success;
    }
    if (upload == SyncResult.failed && pull == SyncResult.failed) {
      return SyncResult.failed;
    }
    return SyncResult.partial;
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
                payload: 'orders',
              );
            }

            await _db.insertBooking(booking);

            // Auto-save booking customer as Online Client
            if (booking.name.isNotEmpty) {
              final String? phone = booking.phone.isNotEmpty
                  ? booking.phone.replaceAll(RegExp(r'\D'), '')
                  : null;
              final custId = phone != null ? 'cust-$phone' : 'cust-booking-${booking.id}';

              final existingCust = (phone != null ? await _db.getCustomerByPhone(phone) : null) ??
                  await _db.getCustomerById(custId);

              if (existingCust == null) {
                final customer = Customer(
                  id: custId,
                  name: booking.name,
                  phone: phone,
                  email: booking.email,
                  source: 'website',
                  address: booking.address,
                  createdAt: booking.createdAt,
                  isSynced: true,
                );
                await _db.insertCustomer(customer, isSync: true);
              }
            }
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
      
      http.Response response;
      if (_auth.isAuthenticated) {
        response = await _auth.makeAuthenticatedRequest(
          '$_adminApiUrl/bills',
          method: 'GET',
        );
      } else {
        response = await http.get(
          Uri.parse('$_adminApiUrl/bills'),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} bills from server');

        for (final item in data) {
          try {
            final bill = Bill.fromMap(item).copyWith(isSynced: true);
            await _db.insertBill(bill, isSync: true);
            await _db.markBillAsSynced(bill.id);
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

  // Sync quotations from server
  Future<SyncResult> _syncQuotations() async {
    try {
      if (!_isOnline) return SyncResult.offline;

      print('Syncing quotations from: $_adminApiUrl/quotations');
      
      http.Response response;
      if (_auth.isAuthenticated) {
        response = await _auth.makeAuthenticatedRequest(
          '$_adminApiUrl/quotations',
          method: 'GET',
        );
      } else {
        response = await http.get(
          Uri.parse('$_adminApiUrl/quotations'),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} quotations from server');

        for (final item in data) {
          try {
            final quotation = Quotation.fromMap(item);
            await _db.insertQuotation(quotation, isSync: true);
          } catch (e) {
            print('Error parsing quotation: $e - Data: $item');
          }
        }
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync quotations error: $e');
      return SyncResult.failed;
    }
  }

  // Sync purchase orders from server
  Future<SyncResult> _syncPurchaseOrders() async {
    try {
      if (!_isOnline) return SyncResult.offline;

      print('Syncing purchase orders from: $_adminApiUrl/purchase-orders');
      
      final response = await _auth.makeAuthenticatedRequest(
        '$_adminApiUrl/purchase-orders',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['items'] ?? [];
        print('Found ${data.length} purchase orders from server');

        for (final item in data) {
          try {
            final po = PurchaseOrder.fromMap(item);
            await _db.insertPurchaseOrder(po, isSync: true);
          } catch (e) {
            print('Error parsing purchase order: $e - Data: $item');
          }
        }
        return SyncResult.success;
      }
      return SyncResult.failed;
    } catch (e) {
      print('Sync purchase orders error: $e');
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
            // Only overwrite local default if cloud has a non-zero rate.
            // A cloud value of 0 means the setting was never configured,
            // so we preserve the local default (typically 18%).
            if (rate > 0) {
              await _db.setSetting('defaultGstRate', rate.toInt().toString());
            }
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
    _quickSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}
