import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/catalog_item.dart';
import '../models/order.dart';
import '../models/booking.dart';
import '../data/manual_customers_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'a1_tech_billing.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _seedManualCustomers(db);
      },
    );
  }

  Future<void> _seedManualCustomers(Database db) async {
    for (final customer in ManualCustomersData.seedCustomers) {
      await db.insert(
        'customers',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add order_id column to orders table
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN order_id TEXT');
      } catch (e) {
        // Ignore if already exists
      }
    }
    if (oldVersion < 3) {
      // Add is_synced column to orders table
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN is_synced INTEGER DEFAULT 0');
      } catch (e) {
        // Ignore if already exists
      }
    }
    if (oldVersion < 4) {
      // Add source column to customers table
      try {
        await db.execute("ALTER TABLE customers ADD COLUMN source TEXT DEFAULT 'manual'");
      } catch (e) {
        // Ignore if already exists
      }
    }
    if (oldVersion < 5) {
      // Create bookings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bookings (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          name TEXT,
          phone TEXT,
          email TEXT,
          city TEXT,
          address TEXT,
          service_type TEXT,
          date TEXT,
          slot TEXT,
          status TEXT DEFAULT 'pending',
          created_at TEXT,
          confirmed_at TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        bill_number TEXT UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_address TEXT,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        gst_amount REAL NOT NULL,
        total REAL NOT NULL,
        payment_mode TEXT DEFAULT 'pending',
        status TEXT DEFAULT 'draft',
        order_id TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT UNIQUE,
        address TEXT,
        email TEXT,
        source TEXT DEFAULT 'manual',
        total_visits INTEGER DEFAULT 0,
        total_spent REAL DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Catalog (Products & Services) table
    await db.execute('''
      CREATE TABLE catalog (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        gst_percent REAL DEFAULT 18,
        category TEXT,
        description TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Orders (cached from website)
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        items TEXT,
        subtotal REAL,
        gst_amount REAL,
        total REAL,
        status TEXT DEFAULT 'pending',
        order_date TEXT,
        bill_id TEXT,
        synced_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Bookings (cached from website)
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT,
        phone TEXT,
        email TEXT,
        city TEXT,
        address TEXT,
        service_type TEXT,
        date TEXT,
        slot TEXT,
        status TEXT DEFAULT 'pending',
        created_at TEXT,
        confirmed_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Sync queue for offline changes
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ==================== BILL OPERATIONS ====================

  Future<String> insertBill(Bill bill, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'bills',
      bill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to sync queue
    if (!isSync) {
      await _addToSyncQueue('bills', bill.id, 'insert', bill.toJson());
    }
    return bill.id;
  }

  Future<void> updateBill(Bill bill, {bool isSync = false}) async {
    final db = await database;
    await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );

    if (!isSync) {
      await _addToSyncQueue('bills', bill.id, 'update', bill.toJson());
    }
  }

  Future<void> updateLocalBillIdAndNumber(String oldId, String newId, String newBillNumber) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Update bill ID, bill_number, and is_synced in 'bills' table
      await txn.update(
        'bills',
        {
          'id': newId,
          'bill_number': newBillNumber,
          'is_synced': 1,
        },
        where: 'id = ?',
        whereArgs: [oldId],
      );

      // 2. Also update in the 'sync_queue' table if there are any remaining references
      await txn.update(
        'sync_queue',
        {
          'record_id': newId,
        },
        where: 'record_id = ? AND table_name = ?',
        whereArgs: [oldId, 'bills'],
      );
    });
  }

  Future<List<Bill>> getBills({
    String? status,
    String? dateFrom,
    String? dateTo,
    int? limit,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Bill.fromMap(maps[i]));
  }

  Future<List<Bill>> getUnsyncedBills() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Bill.fromMap(maps[i]));
  }

  Future<Bill?> getBillById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Bill.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteBill(String id) async {
    final db = await database;
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
    await _addToSyncQueue('bills', id, 'delete', '{"id": "$id"}');
  }

  Future<double> getTodayRevenue() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT SUM(total) as revenue 
      FROM bills 
      WHERE status = 'paid' 
      AND created_at LIKE '$today%'
    ''');

    return result.first['revenue'] as double? ?? 0.0;
  }

  // ==================== CUSTOMER OPERATIONS ====================

  Future<String> insertCustomer(Customer customer, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!isSync) {
      await _addToSyncQueue(
        'customers',
        customer.id,
        'insert',
        customer.toJson(),
      );
    }
    return customer.id;
  }

  Future<void> updateCustomer(Customer customer, {bool isSync = false}) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    if (!isSync) {
      await _addToSyncQueue(
        'customers',
        customer.id,
        'update',
        customer.toJson(),
      );
    }
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await _addToSyncQueue('customers', id, 'delete', '{"id": "$id"}');
  }

  Future<List<Customer>> getCustomers({String? search}) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.isNotEmpty) {
      whereClause = 'name LIKE ? OR phone LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // ==================== CATALOG OPERATIONS ====================

  Future<String> insertCatalogItem(CatalogItem item, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'catalog',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!isSync) {
      await _addToSyncQueue('catalog', item.id, 'insert', item.toJson());
    }
    return item.id;
  }

  Future<void> updateCatalogItem(CatalogItem item, {bool isSync = false}) async {
    final db = await database;
    await db.update(
      'catalog',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    if (!isSync) {
      await _addToSyncQueue('catalog', item.id, 'update', item.toJson());
    }
  }

  Future<void> deleteCatalogItem(String id, {bool isSync = false}) async {
    final db = await database;
    
    // Get type before deleting so we can sync to the correct collection
    String? type;
    if (!isSync) {
      final item = await getCatalogItemById(id);
      type = item?.type;
    }

    await db.delete('catalog', where: 'id = ?', whereArgs: [id]);
    
    if (!isSync && type != null) {
      await _addToSyncQueue('catalog', id, 'delete', '{"id": "$id", "type": "$type"}');
    }
  }

  Future<List<CatalogItem>> getCatalogItems({
    String? type,
    String? category,
  }) async {
    final db = await database;

    String? whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'catalog',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => CatalogItem.fromMap(maps[i]));
  }

  Future<CatalogItem?> getCatalogItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'catalog',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CatalogItem.fromMap(maps.first);
    }
    return null;
  }

  // ==================== ORDER OPERATIONS ====================

  Future<void> insertOrder(Order order, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to sync queue
    if (!isSync) {
      await _addToSyncQueue('orders', order.id, 'insert', order.toJson());
    }
  }

  Future<List<Order>> getOrders({String? status, String? dateFrom}) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'order_date DESC',
    );

    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<Order>> getPendingOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'order_date DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<String?> getLatestOrderDate() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(order_date) as latest FROM orders'
    );
    return result.first['latest'] as String?;
  }

  // ==================== BOOKING OPERATIONS ====================

  Future<void> insertBooking(Booking booking) async {
    final db = await database;
    await db.insert(
      'bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Booking>> getBookings({String? status}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Booking.fromMap(maps[i]));
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final db = await database;
    await db.update(
      'bookings', 
      {'status': status}, 
      where: 'id = ?', 
      whereArgs: [bookingId]
    );
    
    // Add to sync queue for status update
    await _addToSyncQueue('bookings', bookingId, 'update', jsonEncode({'id': bookingId, 'status': status}));
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? billId,
    bool isSync = false,
  }) async {
    if (orderId.startsWith('ORDER-SVC-')) {
      final bookingId = orderId.replaceFirst('ORDER-SVC-', '');
      await updateBookingStatus(bookingId, status);
      return;
    }

    final db = await database;

    final Map<String, dynamic> updates = {'status': status};
    if (billId != null) {
      updates['bill_id'] = billId;
    }

    await db.update('orders', updates, where: 'id = ?', whereArgs: [orderId]);

    // Add to sync queue
    if (!isSync) {
      final payload = Map<String, dynamic>.from(updates);
      payload['id'] = orderId;
      await _addToSyncQueue('orders', orderId, 'update', jsonEncode(payload));
    }
  }

  // ==================== SYNC QUEUE OPERATIONS ====================

  Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    String payload,
  ) async {
    final db = await database;

    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> clearSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markBillAsSynced(String id) async {
    final db = await database;
    await db.update('bills', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SETTINGS OPERATIONS ====================

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // ==================== DASHBOARD STATS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Today's revenue
    final revenueResult = await db.rawQuery('''
      SELECT SUM(total) as revenue 
      FROM bills 
      WHERE status = 'paid' 
      AND created_at LIKE '$today%'
    ''');

    // Today's bills count
    final billsResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM bills 
      WHERE created_at LIKE '$today%'
    ''');

    // Pending orders
    final pendingOrdersResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM orders 
      WHERE status = 'pending'
    ''');

    // Pending bills (draft status)
    final pendingBillsResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM bills 
      WHERE status = 'draft'
    ''');

    // Pending bookings
    final pendingBookingsResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM bookings 
      WHERE status = 'pending' OR status = 'scheduled'
    ''');

    // Total bills count
    final totalBillsResult = await db.rawQuery('SELECT COUNT(*) as count FROM bills');

    return {
      'todayRevenue': revenueResult.first['revenue'] ?? 0.0,
      'todayBills': billsResult.first['count'] ?? 0,
      'pendingOrders': pendingOrdersResult.first['count'] ?? 0,
      'pendingBills': pendingBillsResult.first['count'] ?? 0,
      'totalBills': totalBillsResult.first['count'] ?? 0,
      'pendingBookings': pendingBookingsResult.first['count'] ?? 0,
    };
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
