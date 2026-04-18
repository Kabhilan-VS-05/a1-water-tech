part of 'main.dart';

class BillingRepository {
  BillingRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? kAdminApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  final Map<int, AdminMetrics> _adminMetricsCache = <int, AdminMetrics>{};
  List<OrderRecord>? _ordersCache;
  List<BillRecord>? _recentBillsCache;
  List<BillRecord>? _allBillsCache;
  List<ServiceBookingRecord>? _bookingsCache;

  AdminMetrics? cachedAdminMetrics({int days = 30}) => _adminMetricsCache[days];
  List<OrderRecord>? get cachedOrders => _ordersCache;
  List<BillRecord>? get cachedBills => _recentBillsCache;
  List<BillRecord>? get cachedAllBills => _allBillsCache;
  List<ServiceBookingRecord>? get cachedBookings => _bookingsCache;

  Stream<T> _poll<T>(Future<T> Function() loader) async* {
    yield await loader();
    while (true) {
      await Future<void>.delayed(kAdminPollInterval);
      yield await loader();
    }
  }

  Stream<T> _broadcastPoll<T>(Future<T> Function() loader) {
    return _poll<T>(loader).asBroadcastStream();
  }

  Uri _uri(String path, [Map<String, String?> query = const <String, String?>{}]) {
    final Uri base = Uri.parse('$_baseUrl$path');
    final Map<String, String> filtered = <String, String>{};
    query.forEach((String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        filtered[key] = value;
      }
    });
    return filtered.isEmpty ? base : base.replace(queryParameters: filtered);
  }

  Future<Map<String, dynamic>> _readJson(http.Response response) async {
    final String raw = response.body.trim();
    if (raw.isEmpty) return <String, dynamic>{};
    return _map(jsonDecode(raw));
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, String?> query = const <String, String?>{},
    Object? body,
  }) async {
    final Uri uri = _uri(path, query);
    const Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw UnsupportedError('Unsupported method $method');
    }

    final Map<String, dynamic> payload = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _str(
          payload['message'],
          fallback: 'Request failed with status ${response.statusCode}',
        ),
      );
    }

    return payload;
  }

  Future<List<Map<String, dynamic>>> _fetchItems(
    String path, {
    Map<String, String?> query = const <String, String?>{},
  }) async {
    final Map<String, dynamic> payload = await _requestJson(
      'GET',
      path,
      query: query,
    );
    final List<dynamic> rawItems =
        payload['items'] is List ? payload['items'] as List<dynamic> : <dynamic>[];
    return rawItems.map(_map).toList();
  }

  Future<Map<String, dynamic>> _fetchItem(
    String path, {
    Map<String, String?> query = const <String, String?>{},
  }) async {
    final Map<String, dynamic> payload = await _requestJson(
      'GET',
      path,
      query: query,
    );
    return _map(payload['item']);
  }

  Future<AdminAccessRecord> authorizeAdminSession(AdminIdentity identity) async {
    final Map<String, dynamic> item = _map(
      (
        await _requestJson(
          'POST',
          '/session',
          body: <String, dynamic>{
            'cognitoSub': identity.uid,
            'email': identity.email,
            'displayName': identity.displayName,
            'idToken': identity.idToken,
          },
        )
      )['item'],
    );

    return AdminAccessRecord.fromMap(item);
  }

  Stream<List<OrderRecord>> streamOrders() {
    return _broadcastPoll<List<OrderRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/orders');
      final List<OrderRecord> orders = items
          .map(
            (Map<String, dynamic> item) => OrderRecord.fromMap(
              item,
              docId: _str(
                item['docId'],
                fallback: _str(
                  item['id'],
                  fallback: _str(item['orderId']),
                ),
              ),
            ),
          )
          .toList();

      orders.sort((OrderRecord a, OrderRecord b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      _ordersCache = orders;
      return orders;
    });
  }

  Stream<List<BillRecord>> streamBills() {
    return _broadcastPoll<List<BillRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems(
        '/bills',
        query: const <String, String?>{'limit': '10'},
      );
      final List<BillRecord> bills = items
          .map(
            (Map<String, dynamic> item) => BillRecord.fromMap(
              item,
              docId: _str(
                item['docId'],
                fallback: _str(
                  item['id'],
                  fallback: _str(item['billNumber']),
                ),
              ),
            ),
          )
          .toList();

      bills.sort((BillRecord a, BillRecord b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      _recentBillsCache = bills;
      return bills;
    });
  }

  Stream<List<BillRecord>> streamAllBills() {
    return _broadcastPoll<List<BillRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/bills');
      final List<BillRecord> bills = items
          .map(
            (Map<String, dynamic> item) => BillRecord.fromMap(
              item,
              docId: _str(
                item['docId'],
                fallback: _str(
                  item['id'],
                  fallback: _str(item['billNumber']),
                ),
              ),
            ),
          )
          .toList();

      bills.sort((BillRecord a, BillRecord b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      _allBillsCache = bills;
      return bills;
    });
  }

  Stream<List<ServiceBookingRecord>> streamServiceBookings() {
    return _broadcastPoll<List<ServiceBookingRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/bookings');
      final List<ServiceBookingRecord> bookings = items
          .map(
            (Map<String, dynamic> item) => ServiceBookingRecord.fromMap(
              item,
              bookingId: _str(item['bookingId'], fallback: _str(item['id'])),
            ),
          )
          .where((ServiceBookingRecord booking) => booking.userId.isNotEmpty)
          .toList();

      bookings.sort((ServiceBookingRecord a, ServiceBookingRecord b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      _bookingsCache = bookings;
      return bookings;
    });
  }

  Stream<List<FeedbackRecord>> streamFeedback() {
    return _broadcastPoll<List<FeedbackRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/feedback');
      final List<FeedbackRecord> feedback = items
          .map(
            (Map<String, dynamic> item) => FeedbackRecord.fromMap(
              item,
              docId: _str(item['docId'], fallback: _str(item['id'])),
            ),
          )
          .toList();

      feedback.sort((FeedbackRecord a, FeedbackRecord b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return feedback;
    });
  }

  Stream<BillingConfig> streamBillingConfig() {
    return _broadcastPoll<BillingConfig>(fetchBillingConfig);
  }

  Future<BillingConfig> fetchBillingConfig() async {
    return BillingConfig.fromMap(await _fetchItem('/settings/billing'));
  }

  Stream<BusinessProfile> streamBusinessProfile() {
    return _broadcastPoll<BusinessProfile>(fetchBusinessProfile);
  }

  Future<BusinessProfile> fetchBusinessProfile() async {
    return BusinessProfile.fromMap(await _fetchItem('/settings/business'));
  }

  Future<void> saveBusinessProfile({
    required BusinessProfile profile,
    required String adminName,
  }) async {
    await _requestJson('PUT', '/settings/business', body: <String, dynamic>{
      'companyName': profile.companyName,
      'supportPhone': profile.supportPhone,
      'supportEmail': profile.supportEmail,
      'locality': profile.locality,
      'addressLine1': profile.addressLine1,
      'addressLine2': profile.addressLine2,
      'addressLine3': profile.addressLine3,
      'gstin': profile.gstin,
      'updatedBy': adminName,
    });
  }

  Future<void> saveBillingConfig({
    required BillingConfig config,
    required String adminName,
  }) async {
    await _requestJson('PUT', '/settings/billing', body: <String, dynamic>{
      'companyName': config.companyName,
      'supportPhone': config.supportPhone,
      'invoicePrefix': config.invoicePrefix,
      'gstRate': config.gstRate,
      'gstEnabled': config.gstEnabled,
      'updatedBy': adminName,
    });
  }

  Stream<List<AnnouncementRecord>> streamAnnouncements() {
    return _broadcastPoll<List<AnnouncementRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/announcements');
      final List<AnnouncementRecord> announcements = items
          .map(
            (Map<String, dynamic> item) => AnnouncementRecord.fromMap(
              item,
              docId: _str(item['docId'], fallback: _str(item['id'])),
            ),
          )
          .toList();

      announcements.sort((AnnouncementRecord a, AnnouncementRecord b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return announcements;
    });
  }

  Future<void> upsertAnnouncement({
    String? docId,
    required String title,
    required String message,
    required bool isActive,
    required bool isPinned,
    required String adminName,
  }) async {
    await _requestJson('POST', '/announcements', body: <String, dynamic>{
      'docId': docId,
      'title': title,
      'message': message,
      'isActive': isActive,
      'isPinned': isPinned,
      'updatedBy': adminName,
    });
  }

  Future<void> deleteAnnouncement(String docId) async {
    await _requestJson('DELETE', '/announcements/$docId');
  }

  Future<AdminMetrics> fetchAdminMetrics({int days = 30}) async {
    final Map<String, dynamic> item = await _fetchItem(
      '/metrics',
      query: <String, String?>{'days': '$days'},
    );

    final List<ItemPerformance> topItems =
        (item['topItems'] is List ? item['topItems'] as List<dynamic> : <dynamic>[])
            .map(_map)
            .map(
              (Map<String, dynamic> raw) => ItemPerformance(
                name: _str(raw['name'], fallback: 'Item'),
                quantity: _int(raw['quantity']),
                revenue: _dbl(raw['revenue']),
              ),
            )
            .toList();

    final List<DailyRevenuePoint> dailyRevenue =
        (item['dailyRevenue'] is List ? item['dailyRevenue'] as List<dynamic> : <dynamic>[])
            .map(_map)
            .map(
              (Map<String, dynamic> raw) => DailyRevenuePoint(
                date: _date(raw['date']) ?? DateTime.now(),
                revenue: _dbl(raw['revenue']),
                billsCount: _int(raw['billsCount']),
              ),
            )
            .toList();

    final AdminMetrics metrics = AdminMetrics(
      ordersCount: _int(item['ordersCount']),
      billsCount: _int(item['billsCount']),
      billsInRange: _int(
        item['billsInRange'],
        fallback: _int(item['billsCount']),
      ),
      salesCount: _int(
        item['salesCount'],
        fallback: _int(item['billsCount']),
      ),
      salesCountInRange: _int(
        item['salesCountInRange'],
        fallback: _int(
          item['billsInRange'],
          fallback: _int(item['billsCount']),
        ),
      ),
      bookingsCount: _int(item['bookingsCount']),
      pendingOrders: _int(item['pendingOrders']),
      activeProducts: _int(item['activeProducts']),
      activeServices: _int(item['activeServices']),
      openFeedbackCount: _int(item['openFeedbackCount']),
      totalRevenue: _dbl(item['totalRevenue']),
      revenueInRange: _dbl(item['revenueInRange']),
      topItems: topItems,
      dailyRevenue: dailyRevenue,
    );

    _adminMetricsCache[days] = metrics;
    return metrics;
  }

  Stream<AdminMetrics> streamAdminMetrics({int days = 30}) {
    return _broadcastPoll<AdminMetrics>(() => fetchAdminMetrics(days: days));
  }

  Stream<List<CatalogItemRecord>> streamCatalogItems(String collection) {
    return _broadcastPoll<List<CatalogItemRecord>>(() async {
      final List<Map<String, dynamic>> items = await _fetchItems('/catalog/$collection');
      return items
          .map(
            (Map<String, dynamic> item) => CatalogItemRecord.fromMap(
              item,
              docId: _str(item['docId'], fallback: _str(item['id'])),
              fallbackType: collection,
            ),
          )
          .toList();
    });
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _requestJson('PUT', '/orders/$orderId/status', body: <String, dynamic>{
      'status': status,
    });
  }

  Future<void> updateServiceBookingStatus({
    required ServiceBookingRecord booking,
    required String status,
  }) async {
    await _requestJson(
      'PUT',
      '/bookings/${booking.bookingId}/status',
      body: <String, dynamic>{'status': status},
    );
  }

  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    required String adminName,
  }) async {
    await _requestJson('PUT', '/feedback/$feedbackId/status', body: <String, dynamic>{
      'status': status,
      'updatedBy': adminName,
    });
  }

  Future<void> saveFeedbackResponse({
    required String feedbackId,
    required String response,
    required String adminName,
  }) async {
    await _requestJson('PUT', '/feedback/$feedbackId/response', body: <String, dynamic>{
      'response': response,
      'updatedBy': adminName,
    });
  }

  Future<void> createManualFeedback({
    required String customerName,
    required String phone,
    required String message,
    required int rating,
    required String adminName,
  }) async {
    await _requestJson('POST', '/feedback', body: <String, dynamic>{
      'customerName': customerName,
      'phone': phone,
      'message': message,
      'rating': rating,
      'adminName': adminName,
    });
  }

  Future<void> upsertCatalogItem({
    required String collection,
    String? docId,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) async {
    await _requestJson('POST', '/catalog/$collection', body: <String, dynamic>{
      'docId': docId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    });
  }

  Future<String> generateBill({
    required BillDraft draft,
    required String generatedBy,
    required BillingConfig config,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'source': draft.source,
      'sourceOrderDocId': draft.sourceOrderDocId,
      'sourceOrderId': draft.sourceOrderId,
      'userId': draft.userId,
      'customer': <String, dynamic>{
        'fullName': draft.customerName,
        'phone': draft.phone,
        'city': draft.city,
        'address': draft.address,
        'invoiceType': draft.invoiceType,
        'paymentMethod': draft.paymentMethod,
      },
      'items': draft.items
          .map(
            (BillLine item) => <String, dynamic>{
              'name': item.name,
              'qty': item.quantity,
              'price': item.unitPrice,
            },
          )
          .toList(),
      'generatedBy': generatedBy,
      'config': <String, dynamic>{
        'companyName': config.companyName,
        'supportPhone': config.supportPhone,
        'invoicePrefix': config.invoicePrefix,
        'gstRate': config.gstRate,
        'gstEnabled': config.gstEnabled,
      },
    };

    final Map<String, dynamic> payloadResponse = await _requestJson(
      'POST',
      '/bills',
      body: payload,
    );
    final Map<String, dynamic> item = _map(payloadResponse['item']);
    return _str(item['billNumber']);
  }

  Future<Map<String, dynamic>> fetchBill(String billId) {
    return _fetchItem('/bills/$billId');
  }

  Future<void> updateBill({
    required String billId,
    required Map<String, dynamic> payload,
    required String userId,
  }) async {
    await _requestJson(
      'PUT',
      '/bills/$billId',
      body: <String, dynamic>{...payload, 'userId': userId},
    );
  }
}
