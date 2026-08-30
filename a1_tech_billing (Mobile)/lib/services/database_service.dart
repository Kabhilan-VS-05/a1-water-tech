import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/catalog_item.dart';
import '../models/order.dart';
import '../models/booking.dart';
import '../models/quotation.dart';
import '../models/purchase_order.dart';
import '../data/manual_customers_data.dart';
import 'logger_service.dart';


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
      version: 13,
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
    AppLogger.info('Database upgrade: $oldVersion -> $newVersion', tag: 'Database');

    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN order_id TEXT');
        AppLogger.info('Migration v2: Added order_id column', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v2: order_id column likely exists (${e.toString().split('\n').first})', tag: 'Database');
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN is_synced INTEGER DEFAULT 0');
        AppLogger.info('Migration v3: Added is_synced column', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v3: is_synced column likely exists (${e.toString().split('\n').first})', tag: 'Database');
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE customers ADD COLUMN source TEXT DEFAULT 'manual'");
        AppLogger.info('Migration v4: Added source column', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v4: source column likely exists (${e.toString().split('\n').first})', tag: 'Database');
      }
    }

    if (oldVersion < 5) {
      try {
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
        AppLogger.info('Migration v5: Created bookings table', tag: 'Database');
      } catch (e) {
        AppLogger.error('Migration v5 failed: $e', tag: 'Database');
      }
    }

    if (oldVersion < 6) {
      try {
        await db.execute("ALTER TABLE catalog ADD COLUMN hsn TEXT DEFAULT ''");
        AppLogger.info('Migration v6: Added hsn column', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v6: hsn column likely exists (${e.toString().split('\n').first})', tag: 'Database');
      }
    }

    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE invoice_sequences (
            date TEXT PRIMARY KEY,
            invoice_prefix TEXT NOT NULL,
            counter INTEGER DEFAULT 0,
            updated_at TEXT
          )
        ''');
        AppLogger.info('Migration v7: Created invoice_sequences table', tag: 'Database');
      } catch (e) {
        AppLogger.error('Migration v7 failed: $e', tag: 'Database');
      }
    }

    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE quotations (
            id TEXT PRIMARY KEY,
            quotation_number TEXT UNIQUE,
            customer_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            customer_address TEXT,
            customer_gst TEXT,
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            gst_amount REAL NOT NULL,
            total REAL NOT NULL,
            status TEXT DEFAULT 'draft',
            valid_until TEXT NOT NULL,
            notes TEXT,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            other_charge_label TEXT,
            other_charge_amount REAL,
            is_other_charge_taxable INTEGER DEFAULT 0,
            other_charge_gst_percent REAL,
            terms TEXT,
            is_rounded_off INTEGER DEFAULT 0
          )
        ''');
        AppLogger.info('Migration v8: Created quotations table', tag: 'Database');
      } catch (e) {
        AppLogger.error('Migration v8 failed: $e', tag: 'Database');
      }
    }

    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE purchase_orders (
            id TEXT PRIMARY KEY,
            po_number TEXT UNIQUE,
            customer_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            billing_address TEXT NOT NULL,
            shipping_address TEXT NOT NULL,
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            gst_amount REAL NOT NULL,
            total REAL NOT NULL,
            delivery_date TEXT,
            payment_terms TEXT,
            notes TEXT,
            status TEXT DEFAULT 'draft',
            quotation_id TEXT,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            other_charge_label TEXT,
            other_charge_amount REAL,
            is_other_charge_taxable INTEGER DEFAULT 0,
            other_charge_gst_percent REAL,
            terms TEXT,
            is_rounded_off INTEGER DEFAULT 0
          )
        ''');
        AppLogger.info('Migration v9: Created purchase_orders table', tag: 'Database');
      } catch (e) {
        AppLogger.error('Migration v9 failed: $e', tag: 'Database');
      }
    }

    if (oldVersion < 10) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS invoice_sequences (
            date TEXT PRIMARY KEY,
            invoice_prefix TEXT NOT NULL,
            counter INTEGER DEFAULT 0,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quotations (
            id TEXT PRIMARY KEY,
            quotation_number TEXT UNIQUE,
            customer_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            customer_address TEXT,
            customer_gst TEXT,
            customer_email TEXT,
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            gst_amount REAL NOT NULL,
            total REAL NOT NULL,
            status TEXT DEFAULT 'draft',
            valid_until TEXT NOT NULL,
            notes TEXT,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            other_charge_label TEXT,
            other_charge_amount REAL,
            is_other_charge_taxable INTEGER DEFAULT 0,
            other_charge_gst_percent REAL,
            terms TEXT,
            is_rounded_off INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS purchase_orders (
            id TEXT PRIMARY KEY,
            po_number TEXT UNIQUE,
            customer_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            billing_address TEXT NOT NULL,
            shipping_address TEXT NOT NULL,
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            gst_amount REAL NOT NULL,
            total REAL NOT NULL,
            delivery_date TEXT,
            payment_terms TEXT,
            notes TEXT,
            status TEXT DEFAULT 'draft',
            quotation_id TEXT,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            other_charge_label TEXT,
            other_charge_amount REAL,
            is_other_charge_taxable INTEGER DEFAULT 0,
            other_charge_gst_percent REAL,
            terms TEXT,
            is_rounded_off INTEGER DEFAULT 0
          )
        ''');
        AppLogger.info('Migration v10: Ensured quotations, purchase_orders, and invoice_sequences exist', tag: 'Database');
      } catch (e) {
        AppLogger.error('Migration v10 failed: $e', tag: 'Database');
      }
    }

    if (oldVersion < 11) {
      try {
        await db.execute("ALTER TABLE bills ADD COLUMN customer_gst TEXT");
        await db.execute("ALTER TABLE quotations ADD COLUMN customer_gst TEXT");
        AppLogger.info('Migration v11: Added customer_gst column to bills and quotations', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v11: customer_gst column likely exists (${e.toString().split('\n').first})', tag: 'Database');
      }
    }

    if (oldVersion < 12) {
      try {
        await db.execute("ALTER TABLE quotations ADD COLUMN customer_email TEXT");
        AppLogger.info('Migration v12: Added customer_email column to quotations', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v12: customer_email column likely exists', tag: 'Database');
      }
    }

    if (oldVersion < 13) {
      try {
        await db.execute("ALTER TABLE quotations ADD COLUMN other_charge_label TEXT");
        await db.execute("ALTER TABLE quotations ADD COLUMN other_charge_amount REAL");
        await db.execute("ALTER TABLE quotations ADD COLUMN is_other_charge_taxable INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE quotations ADD COLUMN other_charge_gst_percent REAL");
        await db.execute("ALTER TABLE quotations ADD COLUMN terms TEXT");
        await db.execute("ALTER TABLE quotations ADD COLUMN is_rounded_off INTEGER DEFAULT 0");
        AppLogger.info('Migration v13: Added extra charges and terms to quotations', tag: 'Database');
      } catch (e) {
        AppLogger.debug('Migration v13: columns likely exist', tag: 'Database');
      }
    }

    AppLogger.info('Database upgrade completed', tag: 'Database');
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
        customer_gst TEXT,
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
        hsn TEXT DEFAULT '',
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

    // Invoice Sequences
    await db.execute('''
      CREATE TABLE invoice_sequences (
        date TEXT PRIMARY KEY,
        invoice_prefix TEXT NOT NULL,
        counter INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // Quotations
    await db.execute('''
      CREATE TABLE quotations (
        id TEXT PRIMARY KEY,
        quotation_number TEXT UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_address TEXT,
        customer_gst TEXT,
        customer_email TEXT,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        gst_amount REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'draft',
        valid_until TEXT NOT NULL,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Purchase Orders
    await db.execute('''
      CREATE TABLE purchase_orders (
        id TEXT PRIMARY KEY,
        po_number TEXT UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        billing_address TEXT NOT NULL,
        shipping_address TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        gst_amount REAL NOT NULL,
        total REAL NOT NULL,
        delivery_date TEXT,
        payment_terms TEXT,
        notes TEXT,
        status TEXT DEFAULT 'draft',
        quotation_id TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
    final billToSave = isSync ? bill.copyWith(isSynced: true) : bill;
    await db.insert(
      'bills',
      billToSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to sync queue
    if (!isSync && !bill.isSynced) {
      await _addToSyncQueue('bills', billToSave.id, 'insert', billToSave.toJson());
    }
    return billToSave.id;
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

  Future<int> getInvoiceSequence(String dateStr, String prefix) async {
    final db = await database;
    final formattedDate = dateStr.replaceAll('-', ''); // YYYYMMDD
    final prefixWithDate = '$prefix-$formattedDate-';
    final pattern = '$prefixWithDate%';
    
    String table = 'bills';
    String column = 'bill_number';
    
    if (prefix == 'QT') {
      table = 'quotations';
      column = 'quotation_number';
    } else if (prefix == 'PO') {
      table = 'purchase_orders';
      column = 'po_number';
    }

    final result = await db.rawQuery(
      'SELECT $column FROM $table WHERE $column LIKE ? ORDER BY $column DESC LIMIT 1',
      [pattern],
    );

    if (result.isNotEmpty) {
      final lastNumberStr = result.first[column] as String?;
      if (lastNumberStr != null && lastNumberStr.startsWith(prefixWithDate)) {
        final seqStr = lastNumberStr.substring(prefixWithDate.length);
        final seq = int.tryParse(seqStr);
        if (seq != null) return seq;
      }
    }
    
    return 0;
  }

  Future<void> updateInvoiceSequence(String dateStr, String prefix, int count) async {
    // Sequence is dynamically calculated from actual bills to prevent collisions
  }

  Future<void> updateLocalBillIdAndNumber(String oldId, String newId, String newBillNumber) async {
    final db = await database;
    if (oldId == newId) {
      await markBillAsSynced(newId);
      return;
    }

    // Check if target newId already exists for a different bill in local database
    final existing = await db.query('bills', where: 'id = ?', whereArgs: [newId]);
    String targetId = newId;
    String targetBillNumber = newBillNumber;

    if (existing.isNotEmpty && existing.first['id'] != oldId) {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      targetId = '$newId-$uniqueSuffix';
      targetBillNumber = '$newBillNumber-$uniqueSuffix';
    }

    try {
      await db.transaction((txn) async {
        await txn.update(
          'bills',
          {
            'id': targetId,
            'bill_number': targetBillNumber,
            'is_synced': 1,
          },
          where: 'id = ?',
          whereArgs: [oldId],
        );

        await txn.update(
          'sync_queue',
          {'record_id': targetId},
          where: 'table_name = ? AND record_id = ?',
          whereArgs: ['bills', oldId],
        );
      });
    } catch (e) {
      print('Error updating local bill ID: $e');
    }
  }

  Future<void> updateLocalQuotationIdAndNumber(String oldId, String newId, String newNumber) async {
    final db = await database;
    if (oldId == newId) {
      await markQuotationAsSynced(newId);
      return;
    }

    final existing = await db.query('quotations', where: 'id = ?', whereArgs: [newId]);
    String targetId = newId;
    String targetNumber = newNumber;

    if (existing.isNotEmpty && existing.first['id'] != oldId) {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      targetId = '$newId-$uniqueSuffix';
      targetNumber = '$newNumber-$uniqueSuffix';
    }

    try {
      await db.transaction((txn) async {
        await txn.update(
          'quotations',
          {
            'id': targetId,
            'quotation_number': targetNumber,
            'is_synced': 1,
          },
          where: 'id = ?',
          whereArgs: [oldId],
        );

        await txn.update(
          'sync_queue',
          {'record_id': targetId},
          where: 'table_name = ? AND record_id = ?',
          whereArgs: ['quotations', oldId],
        );
      });
    } catch (e) {
      print('Error updating local quotation ID: $e');
    }
  }

  Future<void> updateLocalPurchaseOrderIdAndNumber(String oldId, String newId, String newNumber) async {
    final db = await database;
    if (oldId == newId) {
      await markPurchaseOrderAsSynced(newId);
      return;
    }

    final existing = await db.query('purchase_orders', where: 'id = ?', whereArgs: [newId]);
    String targetId = newId;
    String targetNumber = newNumber;

    if (existing.isNotEmpty && existing.first['id'] != oldId) {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      targetId = '$newId-$uniqueSuffix';
      targetNumber = '$newNumber-$uniqueSuffix';
    }

    try {
      await db.transaction((txn) async {
        await txn.update(
          'purchase_orders',
          {
            'id': targetId,
            'po_number': targetNumber,
            'is_synced': 1,
          },
          where: 'id = ?',
          whereArgs: [oldId],
        );

        await txn.update(
          'sync_queue',
          {'record_id': targetId},
          where: 'table_name = ? AND record_id = ?',
          whereArgs: ['purchase_orders', oldId],
        );
      });
    } catch (e) {
      print('Error updating local purchase order ID: $e');
    }
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

  Future<double> getWeeklyRevenue() async {
    final db = await database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekStr = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT SUM(total) as revenue 
      FROM bills 
      WHERE status != 'draft' 
      AND created_at >= '$startOfWeekStr'
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

    // Backfill any online customers from orders and bookings table into customers
    await syncCustomersFromOrdersAndBookings();

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

  /// Automatically populates the `customers` table with Online Clients found in `orders` and `bookings`
  Future<void> syncCustomersFromOrdersAndBookings() async {
    try {


      // 1. Extract from orders
      final orders = await getOrders();
      for (final order in orders) {
        if (order.customerName.isNotEmpty) {
          final phone = (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              ? order.customerPhone!.replaceAll(RegExp(r'\D'), '')
              : 'order-${order.id}';

          final existing = await getCustomerByPhone(phone);
          if (existing == null) {
            final customer = Customer(
              id: 'cust-order-$phone',
              name: order.customerName,
              phone: phone.startsWith('order-') ? null : phone,
              source: 'website',
              address: order.customerAddress,
              createdAt: order.orderDate,
              isSynced: true,
            );
            await insertCustomer(customer, isSync: true);
          }
        }
      }

      // 2. Extract from bookings
      final bookings = await getBookings();
      for (final booking in bookings) {
        if (booking.name.isNotEmpty) {
          final phone = booking.phone.replaceAll(RegExp(r'\D'), '');
          final effectivePhone = phone.isNotEmpty ? phone : 'booking-${booking.id}';

          final existing = await getCustomerByPhone(effectivePhone);
          if (existing == null) {
            final customer = Customer(
              id: 'cust-booking-$effectivePhone',
              name: booking.name,
              phone: phone.isNotEmpty ? phone : null,
              email: booking.email,
              source: 'website',
              address: booking.address,
              createdAt: booking.createdAt,
              isSynced: true,
            );
            await insertCustomer(customer, isSync: true);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to sync customers from orders/bookings: $e', tag: 'Database');
    }
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

  Future<void> markQuotationAsSynced(String id) async {
    final db = await database;
    await db.update('quotations', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPurchaseOrderAsSynced(String id) async {
    final db = await database;
    await db.update('purchase_orders', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
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

    // Weekly revenue
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekStr = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String().split('T')[0];

    final revenueResult = await db.rawQuery('''
      SELECT SUM(total) as revenue 
      FROM bills 
      WHERE status != 'draft' 
      AND created_at >= '$startOfWeekStr'
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
      'weeklyRevenue': revenueResult.first['revenue'] ?? 0.0,
      'todayBills': billsResult.first['count'] ?? 0,
      'pendingOrders': pendingOrdersResult.first['count'] ?? 0,
      'pendingBills': pendingBillsResult.first['count'] ?? 0,
      'totalBills': totalBillsResult.first['count'] ?? 0,
      'pendingBookings': pendingBookingsResult.first['count'] ?? 0,
    };
  }

  // Quotation Management
  Future<void> insertQuotation(Quotation quotation, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'quotations', 
      quotation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (!isSync) await _addToSyncQueue('quotations', quotation.id, 'insert', jsonEncode(quotation.toMap()));
  }

  Future<List<Quotation>> getQuotations({String? status}) async {
    final db = await database;
    final query = status != null ? 'SELECT * FROM quotations WHERE status = ? ORDER BY created_at DESC' : 'SELECT * FROM quotations ORDER BY created_at DESC';
    final result = await db.rawQuery(query, status != null ? [status] : []);
    return result.map((map) => Quotation.fromMap(map)).toList();
  }

  Future<Quotation?> getQuotationById(String id) async {
    final db = await database;
    final result = await db.query('quotations', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Quotation.fromMap(result.first) : null;
  }

  Future<List<Quotation>> getUnsyncedQuotations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotations',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Quotation.fromMap(maps[i]));
  }

  Future<void> updateQuotationStatus(String quotationId, String status) async {
    final db = await database;
    await db.update(
      'quotations',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [quotationId],
    );
    await _addToSyncQueue('quotations', quotationId, 'update', jsonEncode({'status': status}));
  }

  // Purchase Order Management
  Future<void> insertPurchaseOrder(PurchaseOrder po, {bool isSync = false}) async {
    final db = await database;
    await db.insert(
      'purchase_orders', 
      po.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (!isSync) await _addToSyncQueue('purchase_orders', po.id, 'insert', jsonEncode(po.toMap()));
  }

  Future<List<PurchaseOrder>> getPurchaseOrders({String? status}) async {
    final db = await database;
    final query = status != null ? 'SELECT * FROM purchase_orders WHERE status = ? ORDER BY created_at DESC' : 'SELECT * FROM purchase_orders ORDER BY created_at DESC';
    final result = await db.rawQuery(query, status != null ? [status] : []);
    return result.map((map) => PurchaseOrder.fromMap(map)).toList();
  }

  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final db = await database;
    final result = await db.query('purchase_orders', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? PurchaseOrder.fromMap(result.first) : null;
  }

  Future<void> updatePurchaseOrderStatus(String poId, String status) async {
    final db = await database;
    await db.update(
      'purchase_orders',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [poId],
    );
    await _addToSyncQueue('purchase_orders', poId, 'update', jsonEncode({'status': status}));
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
