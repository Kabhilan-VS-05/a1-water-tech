import 'dart:async';
import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_pdf.dart';
part 'admin_auth_cognito.dart';
part 'billing_repository_aws.dart';

const String kCatalogImageBucket = 'a1-water-tech';
const String kCatalogImageRegion = 'ap-southeast-2';
const String kCatalogImagePrefix = 'Images';
const String kAdminApiBaseUrl =
    'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin';
const String kAdminCognitoUserPoolId = 'ap-south-1_frjBbY5H9';
const String kAdminCognitoClientId = '7ipnh0krocrne8a98n5kecdtg0';
const String kThemeModeKey = 'app_theme_mode';
const Duration kAdminSessionDuration = Duration(days: 7);
const Duration kAdminPollInterval = Duration(seconds: 5);

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final MacOSFlutterLocalNotificationsPlugin? macOsPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macOsPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<void> showNewOrderNotification(OrderRecord order) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'Alerts when new customer orders are received',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final String customer = order.customerName.isEmpty
        ? 'Unknown customer'
        : order.customerName;
    final String itemsPreview = order.items.isEmpty
        ? 'No items'
        : order.items
              .take(2)
              .map((BillLine item) => item.name)
              .join(', ');
    final String body =
        '${order.orderId} • $customer • Rs ${order.total.toStringAsFixed(2)}\n$itemsPreview';

    await _plugin.show(
      order.docId.hashCode,
      'New Order Received',
      body,
      details,
    );
  }

  Future<void> showNewBookingNotification(ServiceBookingRecord booking) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'new_service_bookings',
      'New Service Bookings',
      channelDescription: 'Alerts when new service bookings are received',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final String customer = booking.customerName.isEmpty
        ? 'Unknown customer'
        : booking.customerName;
    final String body =
        '${booking.serviceType} • $customer\n${booking.dateLabel} ${booking.slot}';

    await _plugin.show(
      booking.bookingId.hashCode,
      'New Service Booking',
      body,
      details,
    );
  }
}

class AdminSessionStore {
  AdminSessionStore._();

  static const String _expiryKey = 'admin_session_expiry_ms';

  static Future<void> markSignedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int expiryMs = DateTime.now()
        .add(kAdminSessionDuration)
        .millisecondsSinceEpoch;
    await prefs.setInt(_expiryKey, expiryMs);
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiryKey);
  }

  static Future<bool> isSessionValid() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? expiryMs = prefs.getInt(_expiryKey);
    if (expiryMs == null) {
      return false;
    }
    return DateTime.now().millisecondsSinceEpoch < expiryMs;
  }

  static Future<DateTime?> expiry() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? expiryMs = prefs.getInt(_expiryKey);
    if (expiryMs == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(expiryMs);
  }
}

class AdminSessionState {
  const AdminSessionState({
    required this.isAuthenticated,
    required this.adminName,
    this.expiry,
  });

  final bool isAuthenticated;
  final String adminName;
  final DateTime? expiry;

  factory AdminSessionState.loggedOut() {
    return const AdminSessionState(
      isAuthenticated: false,
      adminName: '',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await AdminAuthService.instance.initialize();
    await AppNotificationService.instance.initialize();
  } catch (error) {
    initError = error.toString();
  }
  runApp(BillingApp(initError: initError));
}

class BillingThemeController extends InheritedWidget {
  const BillingThemeController({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static BillingThemeController of(BuildContext context) {
    final BillingThemeController? result = context.dependOnInheritedWidgetOfExactType<BillingThemeController>();
    assert(result != null, 'No BillingThemeController found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(BillingThemeController oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

class BillingApp extends StatefulWidget {
  const BillingApp({super.key, this.initError});

  final String? initError;

  @override
  State<BillingApp> createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String mode = prefs.getString(kThemeModeKey) ?? 'light';
    if (!mounted) return;
    setState(() {
      _themeMode = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(kThemeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  ThemeData _buildTheme(Brightness brightness) {
    final ThemeData base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    );
    const Color seed = Color(0xFF0B5FA5);
    final bool isDark = brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF111827) : Colors.white;
    final Color page = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FB);
    final Color fill = isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC);
    final Color border = isDark ? const Color(0xFF334155) : const Color(0xFFD6DFEA);
    final Color textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color textBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: page,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: textBody,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: textBody.withValues(alpha: 0.9),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF0F172A),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BillingThemeController(
      themeMode: _themeMode,
      onThemeModeChanged: _updateThemeMode,
      child: MaterialApp(
      title: 'A1 Tech Billing',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: AppEntryGate(initError: widget.initError),
      ),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key, this.initError});

  final String? initError;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  late final Future<AdminSessionState> _sessionFuture = _restoreSession();

  Future<AdminSessionState> _restoreSession() async {
    if (widget.initError != null) {
      return AdminSessionState.loggedOut();
    }

    final AdminIdentity? identity =
        await AdminAuthService.instance.restoreSession();
    if (identity == null) {
      await AdminSessionStore.clear();
      return AdminSessionState.loggedOut();
    }

    final bool sessionValid = await AdminSessionStore.isSessionValid();
    if (!sessionValid) {
      await AdminAuthService.instance.signOut();
      await AdminSessionStore.clear();
      return AdminSessionState.loggedOut();
    }

    try {
      final AdminAccessRecord admin = await BillingRepository()
          .authorizeAdminSession(identity);

      return AdminSessionState(
        isAuthenticated: true,
        adminName: admin.displayName,
        expiry: await AdminSessionStore.expiry(),
      );
    } catch (_) {
      await AdminAuthService.instance.signOut();
      await AdminSessionStore.clear();
      return AdminSessionState.loggedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminSessionState>(
      future: _sessionFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<AdminSessionState> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final AdminSessionState state =
            snapshot.data ?? AdminSessionState.loggedOut();
        if (!state.isAuthenticated) {
          return LoginPage(initError: widget.initError);
        }

        return DashboardPage(
          adminName: state.adminName,
          repo: BillingRepository(),
          sessionExpiry: state.expiry,
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initError});
  final String? initError;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Align(
                          alignment: Alignment.centerRight,
                          child: _ThemeModeSwitch(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.water_drop,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'A1 Water Tech Admin',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Sign in to manage billing and operations',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.initError != null) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'App init failed: ${widget.initError}',
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _userCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Admin Email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _required,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _login,
                            icon: const Icon(Icons.login),
                            label: Text(
                              _isLoading ? 'Signing in...' : 'Login to Dashboard',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final String enteredEmail = _userCtrl.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
    });

    try {
      final AdminIdentity identity = await AdminAuthService.instance.signIn(
        email: enteredEmail,
        password: _passCtrl.text.trim(),
      );
      final AdminAccessRecord admin = await BillingRepository()
          .authorizeAdminSession(identity);

      await AdminSessionStore.markSignedIn();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardPage(
            adminName: admin.displayName,
            repo: BillingRepository(),
            sessionExpiry: DateTime.now().add(kAdminSessionDuration),
          ),
        ),
      );
    } on CognitoUserConfirmationNecessaryException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('This Cognito account is not confirmed yet.'),
        ),
      );
    } catch (error) {
      await AdminAuthService.instance.signOut();
      await AdminSessionStore.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.adminName,
    required this.repo,
    this.sessionExpiry,
  });
  final String adminName;
  final BillingRepository repo;
  final DateTime? sessionExpiry;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription<List<OrderRecord>>? _orderListener;
  StreamSubscription<List<ServiceBookingRecord>>? _bookingListener;
  bool _orderListenerPrimed = false;
  bool _bookingListenerPrimed = false;
  final Set<String> _knownOrderIds = <String>{};
  final Set<String> _knownBookingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _startNotifications();
  }

  @override
  void dispose() {
    _orderListener?.cancel();
    _bookingListener?.cancel();
    super.dispose();
  }

  void _refreshMetrics() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    await AdminAuthService.instance.signOut();
    await AdminSessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppEntryGate()),
      (Route<dynamic> _) => false,
    );
  }

  void _startNotifications() {
    _orderListener?.cancel();
    _orderListener = widget.repo.streamOrders().listen((
      List<OrderRecord> orders,
    ) async {
      if (!_orderListenerPrimed) {
        for (final OrderRecord order in orders) {
          _knownOrderIds.add(order.docId);
        }
        _orderListenerPrimed = true;
        return;
      }

      for (final OrderRecord order in orders) {
        if (_knownOrderIds.contains(order.docId)) {
          continue;
        }
        _knownOrderIds.add(order.docId);
        await AppNotificationService.instance.showNewOrderNotification(order);
      }
    });

    _bookingListener?.cancel();
    _bookingListener = widget.repo.streamServiceBookings().listen((
      List<ServiceBookingRecord> bookings,
    ) async {
      if (!_bookingListenerPrimed) {
        for (final ServiceBookingRecord booking in bookings) {
          _knownBookingIds.add(booking.bookingId);
        }
        _bookingListenerPrimed = true;
        return;
      }

      for (final ServiceBookingRecord booking in bookings) {
        if (_knownBookingIds.contains(booking.bookingId)) {
          continue;
        }
        _knownBookingIds.add(booking.bookingId);
        await AppNotificationService.instance.showNewBookingNotification(
          booking,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<_AdminFeatureAction> billingOps = <_AdminFeatureAction>[
      _AdminFeatureAction(
        title: 'Automatic Billing',
        subtitle: 'Generate bills from website orders',
        icon: Icons.sync_alt,
        color: const Color(0xFF0B5FA5),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AutomaticBillingPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Manual Billing',
        subtitle: 'Create direct walk-in bills',
        icon: Icons.edit_document,
        color: const Color(0xFF1E88E5),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ManualBillingPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Order Confirmation',
        subtitle: 'Approve orders and service bookings',
        icon: Icons.assignment_turned_in,
        color: const Color(0xFF2E7D32),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderConfirmationPage(repo: widget.repo),
          ),
        ),
      ),
    ];

    final List<_AdminFeatureAction> businessMgmt = <_AdminFeatureAction>[
      _AdminFeatureAction(
        title: 'Manage Catalog',
        subtitle: 'Products and services',
        icon: Icons.inventory_2,
        color: const Color(0xFF7B1FA2),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CatalogManagementPage(repo: widget.repo),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Manage Bills',
        subtitle: 'Edit and share invoices',
        icon: Icons.receipt_long,
        color: const Color(0xFFEF6C00),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BillsManagementPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Feedback Center',
        subtitle: 'Track and resolve customer feedback',
        icon: Icons.rate_review,
        color: const Color(0xFF00897B),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeedbackManagementPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
    ];

    final List<_AdminFeatureAction> adminTools = <_AdminFeatureAction>[
      _AdminFeatureAction(
        title: 'Sales Analytics',
        subtitle: 'Revenue and top-selling performance',
        icon: Icons.insights,
        color: const Color(0xFF6D4C41),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SalesAnalyticsPage(repo: widget.repo),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Announcements',
        subtitle: 'Publish website alerts and banners',
        icon: Icons.campaign,
        color: const Color(0xFFD81B60),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnnouncementsManagementPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
      _AdminFeatureAction(
        title: 'Business Settings',
        subtitle: 'GST, invoice prefix and support info',
        icon: Icons.settings_applications,
        color: const Color(0xFF455A64),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BusinessSettingsPage(
              adminName: widget.adminName,
              repo: widget.repo,
            ),
          ),
        ),
      ),
    ];

    final List<_AdminFeatureAction> quickActions = <_AdminFeatureAction>[
      billingOps[2],
      billingOps[1],
      billingOps[0],
      businessMgmt[1],
    ];

    final List<_AdminFeatureAction> moreTools = <_AdminFeatureAction>[
      businessMgmt[0],
      businessMgmt[2],
      adminTools[0],
      adminTools[1],
      adminTools[2],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          const _ThemeModeSwitch(compact: true),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'refresh') {
                _refreshMetrics();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'refresh',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshMetrics();
          await widget.repo.fetchAdminMetrics(days: 30);
        },
        child: StreamBuilder<AdminMetrics>(
          stream: widget.repo.streamAdminMetrics(days: 30),
          initialData: widget.repo.cachedAdminMetrics(days: 30),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<AdminMetrics> snapshot,
              ) {
                final bool loading =
                    snapshot.connectionState == ConnectionState.waiting;
                final AdminMetrics metrics =
                    snapshot.data ?? AdminMetrics.empty();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _DashboardSimpleHeaderCard(
                      adminName: widget.adminName,
                      sessionExpiry: widget.sessionExpiry,
                      primaryAction: quickActions.first,
                      secondaryAction: quickActions[1],
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: LinearProgressIndicator(minHeight: 4),
                        ),
                      )
                    else if (snapshot.hasError)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Failed to load dashboard metrics.'),
                        ),
                      )
                    else ...<Widget>[
                      _DashboardOverviewCard(
                        metrics: metrics,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Main Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _ToolListCard(items: quickActions),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Recent Bills',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: businessMgmt[1].onTap,
                          child: const Text('Open All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<BillRecord>>(
                      stream: widget.repo.streamBills(),
                      initialData: widget.repo.cachedBills,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<BillRecord>> snapshot,
                          ) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Loading recent bills...'),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Error: ${snapshot.error}'),
                                ),
                              );
                            }
                            final List<BillRecord> bills =
                                snapshot.data ?? <BillRecord>[];
                            if (bills.isEmpty) {
                              return StreamBuilder<List<OrderRecord>>(
                                stream: widget.repo.streamOrders(),
                                initialData: widget.repo.cachedOrders,
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<List<OrderRecord>> orderSnapshot,
                                ) {
                                  final List<OrderRecord> confirmedOrders =
                                      (orderSnapshot.data ?? <OrderRecord>[])
                                          .where(
                                            (OrderRecord order) =>
                                                order.status.toLowerCase() ==
                                                'confirmed',
                                          )
                                          .take(5)
                                          .toList();
                                  if (confirmedOrders.isEmpty) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No bills found yet.'),
                                      ),
                                    );
                                  }
                                  return _PendingBillingPanelSimple(
                                    orders: confirmedOrders,
                                  );
                                },
                              );
                            }
                            return _RecentBillsPanelSimple(
                              bills: bills.take(5).toList(),
                            );
                          },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Other Tools',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _ToolListCard(items: moreTools),
                  ],
                );
              },
        ),
      ),
    );
  }
}

class _ThemeModeSwitch extends StatelessWidget {
  const _ThemeModeSwitch({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final BillingThemeController controller = BillingThemeController.of(
      context,
    );
    final bool isDark = controller.themeMode == ThemeMode.dark;
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.light_mode_outlined,
            size: compact ? 16 : 18,
            color: isDark ? theme.disabledColor : theme.colorScheme.primary,
          ),
          Switch.adaptive(
            value: isDark,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (bool value) => controller.onThemeModeChanged(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          Icon(
            Icons.dark_mode_outlined,
            size: compact ? 16 : 18,
            color: isDark ? theme.colorScheme.primary : theme.disabledColor,
          ),
        ],
      ),
    );
  }
}

class _DashboardSimpleHeaderCard extends StatelessWidget {
  const _DashboardSimpleHeaderCard({
    required this.adminName,
    required this.sessionExpiry,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final String adminName;
  final DateTime? sessionExpiry;
  final _AdminFeatureAction primaryAction;
  final _AdminFeatureAction secondaryAction;

  @override
  Widget build(BuildContext context) {
    final String expiryLabel = sessionExpiry == null
        ? 'Weekly session active'
        : 'Session until ${_formatDateTime(sessionExpiry)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        adminName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(expiryLabel),
                    ],
                  ),
                ),
                const Icon(Icons.dashboard_outlined),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HeroActionButton(
                  action: primaryAction,
                  filled: true,
                ),
                _HeroActionButton(action: secondaryAction),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardOverviewCard extends StatelessWidget {
  const _DashboardOverviewCard({required this.metrics});

  final AdminMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('The most important numbers, without the extra noise.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _SummaryKpi(
                  label: 'Revenue (30d)',
                  value: 'Rs ${metrics.revenueInRange.toStringAsFixed(0)}',
                ),
                _SummaryKpi(
                  label: 'Orders',
                  value: '${metrics.ordersCount}',
                ),
                _SummaryKpi(
                  label: 'Pending Orders',
                  value: '${metrics.pendingOrders}',
                ),
                _SummaryKpi(
                  label: 'Bookings',
                  value: '${metrics.bookingsCount}',
                ),
                _SummaryKpi(
                  label: 'Products',
                  value: '${metrics.activeProducts}',
                ),
                _SummaryKpi(
                  label: 'Services',
                  value: '${metrics.activeServices}',
                ),
                _SummaryKpi(
                  label: 'Open Feedback',
                  value: '${metrics.openFeedbackCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.action,
    this.filled = false,
  });

  final _AdminFeatureAction action;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.dividerColor),
          );

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(action.icon, size: 18),
        const SizedBox(width: 8),
        Text(action.title),
      ],
    );

    if (filled) {
      return FilledButton(
        onPressed: action.onTap,
        style: style,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: action.onTap,
      style: style,
      child: child,
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ToolListCard extends StatelessWidget {
  const _ToolListCard({required this.items});

  final List<_AdminFeatureAction> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List<Widget>.generate(items.length, (int index) {
          final _AdminFeatureAction item = items[index];
          return Column(
            children: <Widget>[
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: item.onTap,
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

// ignore: unused_element
class _RecentBillsPanel extends StatelessWidget {
  const _RecentBillsPanel({required this.bills});

  final List<BillRecord> bills;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: bills.map((BillRecord bill) {
            final bool automatic = bill.source.toLowerCase().contains('order');
            return ListTile(
              title: Text(
                bill.customerName.isEmpty
                    ? bill.billNumber
                    : bill.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${bill.billNumber} • ${bill.source}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                backgroundColor: automatic
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFFFEDD5),
                foregroundColor: automatic
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF9A3412),
                child: Icon(
                  automatic ? Icons.sync_alt_rounded : Icons.edit_note_rounded,
                  size: 20,
                ),
              ),
              trailing: Text(
                'Rs ${bill.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecentBillsPanelSimple extends StatelessWidget {
  const _RecentBillsPanelSimple({required this.bills});

  final List<BillRecord> bills;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: bills.map((BillRecord bill) {
            final bool automatic = bill.source.toLowerCase().contains('order');
            return ListTile(
              title: Text(
                bill.customerName.isEmpty
                    ? bill.billNumber
                    : bill.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${bill.billNumber} - ${bill.source} - ${_titleCase(bill.status)}${bill.createdAt == null ? '' : ' - ${_formatDateTime(bill.createdAt)}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                backgroundColor: automatic
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFFFEDD5),
                foregroundColor: automatic
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF9A3412),
                child: Icon(
                  automatic ? Icons.sync_alt_rounded : Icons.edit_note_rounded,
                  size: 20,
                ),
              ),
              trailing: Text(
                'Rs ${bill.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PendingBillingPanelSimple extends StatelessWidget {
  const _PendingBillingPanelSimple({required this.orders});

  final List<OrderRecord> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            const ListTile(
              leading: Icon(Icons.pending_actions_outlined),
              title: Text('Ready for billing'),
              subtitle: Text(
                'Confirmed website orders are waiting for bill generation.',
              ),
            ),
            ...orders.map((OrderRecord order) {
              return ListTile(
                title: Text(
                  order.customerName.isEmpty ? order.orderId : order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${order.orderId} - ${_formatDateTime(order.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined, size: 20),
                ),
                trailing: Text(
                  'Rs ${order.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AdminFeatureAction {
  const _AdminFeatureAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

// ignore: unused_element
class _DashboardSignal {
  const _DashboardSignal({
    required this.label,
    required this.helper,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String helper;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
}

// ignore: unused_element
class _DashboardCommandGroup {
  const _DashboardCommandGroup({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<_AdminFeatureAction> actions;
}

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({super.key, required this.repo});

  final BillingRepository repo;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final Set<String> _busyActionIds = <String>{};
  final Map<String, String> _orderStatusOverrides = <String, String>{};
  final Map<String, String> _bookingStatusOverrides = <String, String>{};

  String _resolvedOrderStatus(OrderRecord order) {
    return _orderStatusOverrides[order.docId] ?? order.status;
  }

  String _resolvedBookingStatus(ServiceBookingRecord booking) {
    return _bookingStatusOverrides[booking.bookingId] ?? booking.status;
  }

  bool _isBusy(String id) => _busyActionIds.contains(id);

  Future<void> _changeOrderStatus(
    BuildContext context,
    OrderRecord order,
    String status,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busyActionIds.add('order:${order.docId}');
      _orderStatusOverrides[order.docId] = status;
    });

    try {
      await widget.repo.updateOrderStatus(orderId: order.docId, status: status);
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Order ${order.orderId} confirmed.'
                : 'Order ${order.orderId} rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted || !context.mounted) return;
      setState(() {
        _orderStatusOverrides.remove(order.docId);
      });
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busyActionIds.remove('order:${order.docId}');
        });
      }
    }
  }

  Future<void> _changeBookingStatus(
    BuildContext context,
    ServiceBookingRecord booking,
    String status,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busyActionIds.add('booking:${booking.bookingId}');
      _bookingStatusOverrides[booking.bookingId] = status;
    });

    try {
      await widget.repo.updateServiceBookingStatus(
        booking: booking,
        status: status,
      );
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Service booking confirmed.'
                : 'Service booking rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted || !context.mounted) return;
      setState(() {
        _bookingStatusOverrides.remove(booking.bookingId);
      });
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busyActionIds.remove('booking:${booking.bookingId}');
        });
      }
    }
  }

  Future<bool> _confirmRejectDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final bool? approved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    return approved == true;
  }

  Future<void> _openOrderReviewDialog(
    BuildContext context,
    OrderRecord order,
  ) async {
    final String status = _resolvedOrderStatus(order).toLowerCase();
    final bool busy = _isBusy('order:${order.docId}');

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Review ${order.orderId}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _DetailBlock(
                    title: 'Customer Details',
                    lines: <String>[
                      'Name: ${order.customerName}',
                      'Phone: ${order.phone.isEmpty ? 'Not provided' : order.phone}',
                      'City: ${order.city.isEmpty ? 'Not provided' : order.city}',
                      'Address: ${order.address.isEmpty ? 'Not provided' : order.address}',
                      'Invoice: ${order.invoiceType}',
                      'Payment: ${order.paymentMethod}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: 'Order Details',
                    lines: <String>[
                      'Status: ${_titleCase(status)}',
                      'Total: Rs ${order.total.toStringAsFixed(2)}',
                      'Items: ${order.items.length}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((BillLine item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.name}\nQty: ${item.quantity}  •  Rs ${item.unitPrice.toStringAsFixed(2)}  •  Rs ${item.lineTotal.toStringAsFixed(2)}',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            if (status != 'rejected' && status != 'confirmed')
              FilledButton.tonal(
                onPressed: busy
                    ? null
                    : () async {
                        final bool confirmed = await _confirmRejectDialog(
                          context: dialogContext,
                          title: 'Reject Order',
                          message:
                              'Are you sure you want to reject ${order.orderId} for ${order.customerName}?',
                        );
                        if (!confirmed || !mounted || !dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        await _changeOrderStatus(context, order, 'rejected');
                      },
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('Reject'),
              ),
            if (status != 'confirmed')
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        await _changeOrderStatus(context, order, 'confirmed');
                      },
                child: Text(busy ? 'Saving...' : 'Confirm'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openBookingReviewDialog(
    BuildContext context,
    ServiceBookingRecord booking,
  ) async {
    final String status = _resolvedBookingStatus(booking).toLowerCase();
    final bool busy = _isBusy('booking:${booking.bookingId}');

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Review Service Booking'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _DetailBlock(
                    title: 'Customer Details',
                    lines: <String>[
                      'Name: ${booking.customerName}',
                      'Phone: ${booking.phone.isEmpty ? 'Not provided' : booking.phone}',
                      'Email: ${booking.email.isEmpty ? 'Not provided' : booking.email}',
                      'City: ${booking.city.isEmpty ? 'Not provided' : booking.city}',
                      'Address: ${booking.address.isEmpty ? 'Not provided' : booking.address}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailBlock(
                    title: 'Booking Details',
                    lines: <String>[
                      'Service: ${booking.serviceType}',
                      'Date: ${booking.dateLabel}',
                      'Slot: ${booking.slot}',
                      'Status: ${_titleCase(status)}',
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            if (status != 'rejected' && status != 'confirmed')
              FilledButton.tonal(
                onPressed: busy
                    ? null
                    : () async {
                        final bool confirmed = await _confirmRejectDialog(
                          context: dialogContext,
                          title: 'Reject Service Booking',
                          message:
                              'Reject ${booking.serviceType} for ${booking.customerName}?',
                        );
                        if (!confirmed || !mounted || !dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        await _changeBookingStatus(
                          context,
                          booking,
                          'rejected',
                        );
                      },
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('Reject'),
              ),
            if (status != 'confirmed')
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        await _changeBookingStatus(
                          context,
                          booking,
                          'confirmed',
                        );
                      },
                child: Text(busy ? 'Saving...' : 'Confirm'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Future<void> ensureFreshToken = Future<void>.value();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: FutureBuilder<void>(
        future: ensureFreshToken,
        builder: (BuildContext context, AsyncSnapshot<void> tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Product Orders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<OrderRecord>>(
                stream: widget.repo.streamOrders(),
                initialData: widget.repo.cachedOrders,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<OrderRecord>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Loading product orders...'),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }
                      final List<OrderRecord> orders =
                          snapshot.data ?? <OrderRecord>[];
                      if (orders.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No product orders found.'),
                          ),
                        );
                      }
                      return Column(
                        children: orders.map((OrderRecord order) {
                          final String status = _resolvedOrderStatus(order);
                          final bool busy = _isBusy('order:${order.docId}');
                          return Card(
                            child: ListTile(
                              onTap: () => _openOrderReviewDialog(context, order),
                              title: Text(
                                '${order.orderId} - ${order.customerName}',
                              ),
                              subtitle: Text(
                                '${order.items.length} item(s) | ${_titleCase(status)}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Text('Rs ${order.total.toStringAsFixed(2)}'),
                                  if (busy)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _openOrderReviewDialog(context, order),
                                      child: Text(
                                        status.toLowerCase() == 'confirmed'
                                            ? 'View'
                                            : 'Review',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
              ),
              const SizedBox(height: 20),
              Text(
                'Service Bookings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ServiceBookingRecord>>(
                stream: widget.repo.streamServiceBookings(),
                initialData: widget.repo.cachedBookings,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<ServiceBookingRecord>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Loading service bookings...'),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }
                      final List<ServiceBookingRecord> bookings =
                          snapshot.data ?? <ServiceBookingRecord>[];
                      if (bookings.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No service bookings found.'),
                          ),
                        );
                      }
                      return Column(
                        children: bookings.map((ServiceBookingRecord booking) {
                          final String status = _resolvedBookingStatus(booking);
                          final bool busy = _isBusy('booking:${booking.bookingId}');
                          return Card(
                            child: ListTile(
                              onTap: () =>
                                  _openBookingReviewDialog(context, booking),
                              title: Text(
                                '${booking.serviceType} - ${booking.customerName}',
                              ),
                              subtitle: Text(
                                '${booking.dateLabel} ${booking.slot} | ${_titleCase(status)}',
                              ),
                              trailing: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : FilledButton.tonal(
                                      onPressed: () => _openBookingReviewDialog(
                                        context,
                                        booking,
                                      ),
                                      child: Text(
                                        status.toLowerCase() == 'confirmed'
                                            ? 'View'
                                            : 'Review',
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      );
                    },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogManagementPage extends StatefulWidget {
  const CatalogManagementPage({super.key, required this.repo});

  final BillingRepository repo;

  @override
  State<CatalogManagementPage> createState() => _CatalogManagementPageState();
}

class _CatalogManagementPageState extends State<CatalogManagementPage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _CatalogSection(
            title: 'Products',
            stream: widget.repo.streamCatalogItems('products'),
            onAdd: () => _openCatalogEditor('products'),
            onEdit: (CatalogItemRecord item) =>
                _openCatalogEditor('products', item: item),
          ),
          const SizedBox(height: 20),
          _CatalogSection(
            title: 'Services',
            stream: widget.repo.streamCatalogItems('services'),
            onAdd: () => _openCatalogEditor('services'),
            onEdit: (CatalogItemRecord item) =>
                _openCatalogEditor('services', item: item),
          ),
        ],
      ),
    );
  }

  Future<void> _openCatalogEditor(
    String collection, {
    CatalogItemRecord? item,
  }) async {
    final _CatalogEditorDraft? draft = await showDialog<_CatalogEditorDraft>(
      context: context,
      builder: (BuildContext dialogContext) => _CatalogEditorDialog(
        item: item,
        onUploadImage: () => _pickAndUploadCatalogImage(
          collection,
          existingDocId: item?.docId,
        ),
      ),
    );

    if (draft != null) {
      await widget.repo.upsertCatalogItem(
        collection: collection,
        docId: item?.docId,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        imageUrl: draft.imageUrl,
      );
    }
  }

  Future<String> _pickAndUploadCatalogImage(
    String collection, {
    String? existingDocId,
  }) async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (file == null) {
      return '';
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected file could not be read.');
    }

    final String extension =
        file.name.split('.').last.trim().toLowerCase().replaceAll('.', '');
    final String safeExtension = extension.isEmpty ? 'jpg' : extension;
    final String objectId =
        existingDocId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final String objectPath =
        '$kCatalogImagePrefix/$collection-$objectId.$safeExtension';
    final Uri uploadUri = _catalogImageUri(objectPath);

    final http.Response response = await http.put(
      uploadUri,
      headers: <String, String>{
        'Content-Type': _contentTypeForExtension(safeExtension),
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return uploadUri.toString();
    }

    throw Exception(
      _describeCatalogUploadFailure(
        statusCode: response.statusCode,
        body: response.body,
      ),
    );
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Uri _catalogImageUri(String objectPath) {
    return Uri.https(
      '$kCatalogImageBucket.s3.$kCatalogImageRegion.amazonaws.com',
      '/$objectPath',
    );
  }

  String _describeCatalogUploadFailure({
    required int statusCode,
    required String body,
  }) {
    if (statusCode == 403) {
      return 'S3 denied the upload. Allow PUT access for '
          '$kCatalogImagePrefix/ in bucket $kCatalogImageBucket or use a '
          'presigned URL flow.';
    }

    if (statusCode == 404) {
      return 'S3 bucket or folder path was not found. Confirm bucket '
          '$kCatalogImageBucket exists in $kCatalogImageRegion and that '
          '$kCatalogImagePrefix/ is valid.';
    }

    if (statusCode == 400) {
      return 'S3 rejected the upload request. Check bucket CORS and upload '
          'settings for $kCatalogImageBucket.';
    }

    final String trimmedBody = body.trim();
    if (trimmedBody.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(trimmedBody);
        if (decoded is Map<String, Object?>) {
          final Object? message = decoded['message'] ?? decoded['error'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      } catch (_) {
        if (trimmedBody.length <= 180) {
          return trimmedBody;
        }
      }
    }

    return 'Image upload failed (HTTP $statusCode).';
  }
}

class _CatalogEditorDialog extends StatefulWidget {
  const _CatalogEditorDialog({required this.item, required this.onUploadImage});

  final CatalogItemRecord? item;
  final Future<String> Function() onUploadImage;

  @override
  State<_CatalogEditorDialog> createState() => _CatalogEditorDialogState();
}

class _CatalogEditorDialogState extends State<_CatalogEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _descCtrl = TextEditingController(text: widget.item?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.item == null ? '' : widget.item!.price.toStringAsFixed(2),
    );
    _imageCtrl = TextEditingController(text: widget.item?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.item == null ? 'Add Item' : 'Edit Item';
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredField,
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _imageCtrl,
                  builder: (
                    BuildContext context,
                    TextEditingValue value,
                    Widget? child,
                  ) {
                    final String imageUrl = value.text.trim();
                    return Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploading ? null : _uploadImage,
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _isUploading
                                      ? 'Uploading...'
                                      : 'Upload Image',
                                ),
                              ),
                            ),
                            if (imageUrl.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Remove image',
                                onPressed: _isUploading
                                    ? null
                                    : () => _imageCtrl.clear(),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText:
                                'Auto-filled after upload or paste manually',
                          ),
                        ),
                        if (imageUrl.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              height: 170,
                              color: const Color(0xFFF8FAFC),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const Center(
                                    child: Text('Image preview unavailable'),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isUploading ? null : _closeWithoutSaving,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUploading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploading = true);
    try {
      final String imageUrl = await widget.onUploadImage();
      if (!mounted || imageUrl.isEmpty) {
        return;
      }
      _imageCtrl.text = imageUrl;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _closeWithoutSaving() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _CatalogEditorDraft(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        imageUrl: _imageCtrl.text.trim(),
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class _CatalogEditorDraft {
  const _CatalogEditorDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  final String name;
  final String description;
  final double price;
  final String imageUrl;
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.title,
    required this.stream,
    required this.onAdd,
    required this.onEdit,
  });

  final String title;
  final Stream<List<CatalogItemRecord>> stream;
  final VoidCallback onAdd;
  final ValueChanged<CatalogItemRecord> onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CatalogItemRecord>>(
              stream: stream,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<CatalogItemRecord>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Loading...'),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final List<CatalogItemRecord> items =
                        snapshot.data ?? <CatalogItemRecord>[];
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No items available.'),
                      );
                    }
                    return Column(
                      children: items.map((CatalogItemRecord item) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          subtitle: Text(item.description),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text('Rs ${item.price.toStringAsFixed(2)}'),
                              IconButton(
                                onPressed: () => onEdit(item),
                                icon: const Icon(Icons.edit),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class AutomaticBillingPage extends StatelessWidget {
  const AutomaticBillingPage({
    super.key,
    required this.adminName,
    required this.repo,
  });
  final String adminName;
  final BillingRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automatic Billing')),
      body: StreamBuilder<List<OrderRecord>>(
        stream: repo.streamOrders(),
        initialData: repo.cachedOrders,
        builder:
            (BuildContext context, AsyncSnapshot<List<OrderRecord>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }
              final List<OrderRecord> orders = snapshot.data ?? <OrderRecord>[];
              if (orders.isEmpty) {
                return const Center(child: Text('No website orders.'));
              }
              final List<OrderRecord> eligible = orders
                  .where(
                    (OrderRecord o) =>
                        o.status.toLowerCase() == 'confirmed' ||
                        o.status.toLowerCase() == 'pending',
                  )
                  .toList();
              if (eligible.isEmpty) {
                return const Center(
                  child: Text('No confirmed/pending orders available.'),
                );
              }
              return ListView.builder(
                itemCount: eligible.length,
                itemBuilder: (BuildContext context, int i) {
                  final OrderRecord order = eligible[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text('${order.orderId} - ${order.customerName}'),
                      subtitle: Text(
                        '${order.items.length} item(s) | ${order.status}',
                      ),
                      trailing: Text('Rs ${order.total.toStringAsFixed(2)}'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BillEditorPage(
                            adminName: adminName,
                            repo: repo,
                            draft: BillDraft.fromOrder(order),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}

class ManualBillingPage extends StatelessWidget {
  const ManualBillingPage({
    super.key,
    required this.adminName,
    required this.repo,
  });
  final String adminName;
  final BillingRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Billing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BillEditorPage(
                adminName: adminName,
                repo: repo,
                draft: BillDraft.empty(),
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Create Manual Bill'),
        ),
      ),
    );
  }
}

class BillEditorPage extends StatefulWidget {
  const BillEditorPage({
    super.key,
    required this.adminName,
    required this.repo,
    required this.draft,
  });
  final String adminName;
  final BillingRepository repo;
  final BillDraft draft;

  @override
  State<BillEditorPage> createState() => _BillEditorPageState();
}

class _BillEditorPageState extends State<BillEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _invoiceCtrl;
  late final TextEditingController _paymentCtrl;
  final List<LineEditor> _lines = <LineEditor>[];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.customerName);
    _phoneCtrl = TextEditingController(text: widget.draft.phone);
    _cityCtrl = TextEditingController(text: widget.draft.city);
    _addressCtrl = TextEditingController(text: widget.draft.address);
    _invoiceCtrl = TextEditingController(text: widget.draft.invoiceType);
    _paymentCtrl = TextEditingController(text: widget.draft.paymentMethod);
    if (widget.draft.items.isEmpty) {
      _lines.add(LineEditor());
    } else {
      for (final BillLine item in widget.draft.items) {
        _lines.add(
          LineEditor(
            name: item.name,
            qty: '${item.quantity}',
            price: '${item.unitPrice}',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _invoiceCtrl.dispose();
    _paymentCtrl.dispose();
    for (final LineEditor line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.draft.source == 'automatic' ? 'Edit Auto Bill' : 'Manual Bill',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(labelText: 'Invoice Type'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paymentCtrl,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            ..._itemRows(),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _preview,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _itemRows() {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < _lines.length; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _lines[i].name,
                  decoration: InputDecoration(labelText: 'Item ${i + 1}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _lines[i].qty,
                  decoration: const InputDecoration(labelText: 'Qty'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _lines[i].price,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
              ),
              IconButton(
                onPressed: _lines.length == 1 ? null : () => _removeLine(i),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _addLine() => setState(() => _lines.add(LineEditor()));

  void _removeLine(int i) => setState(() {
    _lines[i].dispose();
    _lines.removeAt(i);
  });

  void _preview() {
    if (!_formKey.currentState!.validate()) return;
    final List<BillLine> items = <BillLine>[];
    for (final LineEditor line in _lines) {
      final String name = line.name.text.trim();
      if (name.isEmpty) continue;
      items.add(
        BillLine(
          name: name,
          quantity: int.tryParse(line.qty.text.trim()) ?? 1,
          unitPrice: double.tryParse(line.price.text.trim()) ?? 0,
        ),
      );
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    final BillDraft draft = widget.draft.copyWith(
      customerName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      invoiceType: _invoiceCtrl.text.trim(),
      paymentMethod: _paymentCtrl.text.trim(),
      items: items,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BillSummaryPage(
          adminName: widget.adminName,
          repo: widget.repo,
          draft: draft,
        ),
      ),
    );
  }
}

class BillSummaryPage extends StatefulWidget {
  const BillSummaryPage({
    super.key,
    required this.adminName,
    required this.repo,
    required this.draft,
  });
  final String adminName;
  final BillingRepository repo;
  final BillDraft draft;

  @override
  State<BillSummaryPage> createState() => _BillSummaryPageState();
}

class _BillSummaryPageState extends State<BillSummaryPage> {
  bool _saving = false;
  late final Future<BillingConfig> _configFuture = widget.repo.fetchBillingConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Summary')),
      body: FutureBuilder<BillingConfig>(
        future: _configFuture,
        builder: (BuildContext context, AsyncSnapshot<BillingConfig> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final BillingConfig config = snapshot.data ?? BillingConfig.defaults();
          final double subtotal = widget.draft.subtotal;
          final double gstRate = config.gstEnabled ? config.gstRate : 0;
          final double gstAmount = subtotal * gstRate;
          final double total = subtotal + gstAmount;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.draft.source == 'automatic'
                            ? 'Automatic Billing'
                            : 'Manual Billing',
                      ),
                      Text('Customer: ${widget.draft.customerName}'),
                      Text('Phone: ${widget.draft.phone}'),
                      const SizedBox(height: 4),
                      Text('Company: ${config.companyName}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      ...widget.draft.items.map(
                        (BillLine i) => Row(
                          children: <Widget>[
                            Expanded(child: Text('${i.name} x ${i.quantity}')),
                            Text('Rs ${i.lineTotal.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      const Divider(),
                      _sumRow('Subtotal', subtotal),
                      _sumRow(
                        'GST (${(gstRate * 100).toStringAsFixed(2)}%)',
                        gstAmount,
                      ),
                      _sumRow('Total', total, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : () => _generate(config),
                icon: const Icon(Icons.receipt_long),
                label: Text(_saving ? 'Generating...' : 'Generate Bill'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sumRow(String label, double val, {bool bold = false}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ),
        Text(
          'Rs ${val.toStringAsFixed(2)}',
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ],
    );
  }

  Future<void> _generate(BillingConfig config) async {
    setState(() => _saving = true);
    try {
      final String billNo = await widget.repo.generateBill(
        draft: widget.draft,
        generatedBy: widget.adminName,
        config: config,
      );
      if (!context.mounted) return;
      final double subtotal = widget.draft.subtotal;
      final double gstRate = config.gstEnabled ? config.gstRate : 0;
      final double gstAmount = subtotal * gstRate;
      final double total = subtotal + gstAmount;

      final List<Map<String, dynamic>> items = widget.draft.items
          .map(
            (BillLine i) => <String, dynamic>{
              'name': i.name,
              'qty': i.quantity,
              'price': i.unitPrice,
            },
          )
          .toList();

      final Uint8List pdfBytes = await buildBillingPdf(
        billNumber: billNo,
        generatedBy: widget.adminName,
        companyName: config.companyName,
        supportPhone: config.supportPhone,
        customerName: widget.draft.customerName,
        phone: widget.draft.phone,
        city: widget.draft.city,
        address: widget.draft.address,
        invoiceType: widget.draft.invoiceType,
        paymentMethod: widget.draft.paymentMethod,
        items: items,
        subtotal: subtotal,
        gstRate: gstRate,
        gstAmount: gstAmount,
        total: total,
      );

      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      await showDialog<void>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Bill confirmed'),
            content: Text('Generated: $billNo'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: '$billNo.pdf',
                  );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Download / Share PDF'),
              ),
              TextButton(
                onPressed: () async {
                  await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Print'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class FeedbackManagementPage extends StatefulWidget {
  const FeedbackManagementPage({
    super.key,
    required this.adminName,
    required this.repo,
  });

  final String adminName;
  final BillingRepository repo;

  @override
  State<FeedbackManagementPage> createState() => _FeedbackManagementPageState();
}

class _FeedbackManagementPageState extends State<FeedbackManagementPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Center'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _openManualFeedbackDialog,
            icon: const Icon(Icons.add_comment),
            label: const Text('Add Feedback'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<FeedbackRecord>>(
        stream: widget.repo.streamFeedback(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<FeedbackRecord>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<FeedbackRecord> allFeedback =
              snapshot.data ?? <FeedbackRecord>[];
          final Map<String, int> stats = _feedbackStats(allFeedback);
          final List<FeedbackRecord> filtered = _applyFilters(allFeedback);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _FeedbackStatChip(
                    label: 'Total',
                    value: stats['total'] ?? 0,
                    color: Colors.blueGrey,
                  ),
                  _FeedbackStatChip(
                    label: 'Open',
                    value: stats['open'] ?? 0,
                    color: Colors.orange,
                  ),
                  _FeedbackStatChip(
                    label: 'In Progress',
                    value: stats['in_progress'] ?? 0,
                    color: Colors.blue,
                  ),
                  _FeedbackStatChip(
                    label: 'Resolved',
                    value: stats['resolved'] ?? 0,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget searchField = TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Search customer / phone / message',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  );
                  final Widget statusDropdown = DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('All'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'open',
                        child: Text('Open'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      setState(() => _statusFilter = value);
                    },
                  );

                  if (constraints.maxWidth < 640) {
                    return Column(
                      children: <Widget>[
                        searchField,
                        const SizedBox(height: 12),
                        statusDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(flex: 3, child: searchField),
                      const SizedBox(width: 12),
                      Expanded(child: statusDropdown),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No feedback found for the selected filters.'),
                  ),
                )
              else
                ...filtered.map(_buildFeedbackCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackRecord feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    feedback.customerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(feedback.status)),
                  avatar: const Icon(Icons.flag_circle, size: 16),
                ),
              ],
            ),
            if (feedback.phone.isNotEmpty) Text('Phone: ${feedback.phone}'),
            if (feedback.orderId.isNotEmpty) Text('Order: ${feedback.orderId}'),
            const SizedBox(height: 6),
            Text(feedback.message),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.star_rate, size: 16),
                  label: Text(
                    feedback.rating > 0
                        ? 'Rating: ${feedback.rating}/5'
                        : 'Rating: Not provided',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.access_time, size: 16),
                  label: Text(_formatDateTime(feedback.createdAt)),
                ),
              ],
            ),
            if (feedback.adminResponse.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Admin reply: ${feedback.adminResponse}'),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _openReplyDialog(feedback),
                  icon: const Icon(Icons.reply),
                  label: Text(
                    feedback.adminResponse.isEmpty ? 'Reply' : 'Edit Reply',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: feedback.status == 'open'
                      ? () => _updateFeedbackStatus(
                            feedback: feedback,
                            status: 'in_progress',
                          )
                      : null,
                  child: const Text('Start'),
                ),
                FilledButton.tonal(
                  onPressed: feedback.status == 'resolved'
                      ? null
                      : () => _updateFeedbackStatus(
                            feedback: feedback,
                            status: 'resolved',
                          ),
                  child: const Text('Resolve'),
                ),
                TextButton(
                  onPressed: feedback.status == 'open'
                      ? null
                      : () => _updateFeedbackStatus(
                            feedback: feedback,
                            status: 'open',
                          ),
                  child: const Text('Re-open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FeedbackRecord> _applyFilters(List<FeedbackRecord> allFeedback) {
    final String query = _searchCtrl.text.trim().toLowerCase();
    return allFeedback.where((FeedbackRecord feedback) {
      final bool statusMatches =
          _statusFilter == 'all' || feedback.status == _statusFilter;
      if (!statusMatches) return false;
      if (query.isEmpty) return true;
      final String haystack =
          '${feedback.customerName} ${feedback.phone} ${feedback.message} ${feedback.orderId}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Map<String, int> _feedbackStats(List<FeedbackRecord> allFeedback) {
    final Map<String, int> stats = <String, int>{
      'total': allFeedback.length,
      'open': 0,
      'in_progress': 0,
      'resolved': 0,
    };
    for (final FeedbackRecord feedback in allFeedback) {
      if (stats.containsKey(feedback.status)) {
        stats[feedback.status] = (stats[feedback.status] ?? 0) + 1;
      }
    }
    return stats;
  }

  Future<void> _updateFeedbackStatus({
    required FeedbackRecord feedback,
    required String status,
  }) async {
    await widget.repo.updateFeedbackStatus(
      feedbackId: feedback.docId,
      status: status,
      adminName: widget.adminName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Feedback marked as ${_statusLabel(status)}')));
  }

  Future<void> _openReplyDialog(FeedbackRecord feedback) async {
    final TextEditingController replyCtrl = TextEditingController(
      text: feedback.adminResponse,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reply to ${feedback.customerName}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: replyCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin reply',
                hintText: 'Write your reply or resolution note',
              ),
              maxLines: 4,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (save == true) {
      await widget.repo.saveFeedbackResponse(
        feedbackId: feedback.docId,
        response: replyCtrl.text.trim(),
        adminName: widget.adminName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply saved.')));
    }

    replyCtrl.dispose();
  }

  Future<void> _openManualFeedbackDialog() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController messageCtrl = TextEditingController();
    final TextEditingController ratingCtrl = TextEditingController(text: '5');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Manual Feedback'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer name',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: ratingCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rating (1-5)'),
                      validator: (String? value) {
                        final int? rating = int.tryParse((value ?? '').trim());
                        if (rating == null || rating < 1 || rating > 5) {
                          return 'Enter a value from 1 to 5';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: messageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Feedback message',
                      ),
                      maxLines: 4,
                      validator: _required,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (save == true) {
      await widget.repo.createManualFeedback(
        customerName: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        message: messageCtrl.text.trim(),
        rating: int.tryParse(ratingCtrl.text.trim()) ?? 0,
        adminName: widget.adminName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Feedback added.')));
    }

    nameCtrl.dispose();
    phoneCtrl.dispose();
    messageCtrl.dispose();
    ratingCtrl.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Open';
    }
  }
}

class _FeedbackStatChip extends StatelessWidget {
  const _FeedbackStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key, required this.repo});

  final BillingRepository repo;

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  int _days = 30;
  int _selectedTrendIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        actions: <Widget>[
          DropdownButton<int>(
            value: _days,
            underline: const SizedBox.shrink(),
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 7, child: Text('7 days')),
              DropdownMenuItem<int>(value: 30, child: Text('30 days')),
              DropdownMenuItem<int>(value: 90, child: Text('90 days')),
            ],
            onChanged: (int? value) {
              if (value == null) return;
              setState(() {
                _days = value;
                _selectedTrendIndex = 0;
              });
            },
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<AdminMetrics>(
        stream: widget.repo.streamAdminMetrics(days: _days),
        initialData: widget.repo.cachedAdminMetrics(days: _days),
        builder: (BuildContext context, AsyncSnapshot<AdminMetrics> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final AdminMetrics metrics = snapshot.data ?? AdminMetrics.empty();
          final List<DailyRevenuePoint> trend = metrics.dailyRevenue;
          if (trend.isNotEmpty && _selectedTrendIndex >= trend.length) {
            _selectedTrendIndex = trend.length - 1;
          }
          final DailyRevenuePoint? selectedTrendPoint = trend.isEmpty
              ? null
              : trend[_selectedTrendIndex];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _MetricCard(
                    title: 'Revenue ($_days d)',
                    value: 'Rs ${metrics.revenueInRange.toStringAsFixed(2)}',
                    icon: Icons.show_chart,
                  ),
                  _MetricCard(
                    title: 'Avg / Day',
                    value: 'Rs ${metrics.averageDailyRevenue.toStringAsFixed(2)}',
                    icon: Icons.timeline,
                  ),
                  _MetricCard(
                    title: 'Sales ($_days d)',
                    value: '${metrics.salesCountInRange}',
                    icon: Icons.receipt_long,
                  ),
                  _MetricCard(
                    title: 'Pending',
                    value: '${metrics.pendingOrders}',
                    icon: Icons.pending_actions,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Revenue Trend',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedTrendPoint == null
                                      ? 'No billed activity in the selected window.'
                                      : '${selectedTrendPoint.label}  |  ${selectedTrendPoint.billsCount} bill(s)',
                                ),
                              ],
                            ),
                          ),
                          if (selectedTrendPoint != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  'Rs ${selectedTrendPoint.revenue.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  selectedTrendPoint.isToday
                                      ? 'Today'
                                      : selectedTrendPoint.shortWeekday,
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SelectableRevenueChart(
                        points: trend,
                        selectedIndex: _selectedTrendIndex,
                        onSelected: (int index) {
                          setState(() => _selectedTrendIndex = index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Top Selling Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clean view of the best performers by revenue.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      if (metrics.topItems.isEmpty)
                        const Text('No item analytics available yet.')
                      else ...List<Widget>.generate(metrics.topItems.take(5).length, (
                          int index,
                        ) {
                          final ItemPerformance item = metrics.topItems[index];
                          final double maxValue = metrics.maxTopItemRevenue;
                          final double fraction = maxValue <= 0
                              ? 0
                              : (item.revenue / maxValue).clamp(0, 1);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Rs ${item.revenue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF0B5FA5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Qty sold: ${item.quantity}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    value: fraction,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0B5FA5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableRevenueChart extends StatelessWidget {
  const _SelectableRevenueChart({
    required this.points,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DailyRevenuePoint> points;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6DFEA)),
        ),
        child: const Text('No revenue data available yet.'),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) {
            if (points.length == 1 || width <= 0) {
              onSelected(0);
              return;
            }
            final double ratio = (details.localPosition.dx / width).clamp(0, 1);
            final int index = (ratio * (points.length - 1)).round();
            onSelected(index);
          },
          child: SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _RevenueTrendPainter(
                points: points,
                selectedIndex: selectedIndex,
                textDirection: Directionality.of(context),
              ),
              child: Container(),
            ),
          ),
        );
      },
    );
  }
}

class _RevenueTrendPainter extends CustomPainter {
  _RevenueTrendPainter({
    required this.points,
    required this.selectedIndex,
    required this.textDirection,
  });

  final List<DailyRevenuePoint> points;
  final int selectedIndex;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 18;
    const double rightPad = 18;
    const double topPad = 16;
    const double bottomPad = 30;
    final Rect chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final Paint bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    final RRect bg = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas.drawRRect(bg, bgPaint);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i += 1) {
      final double y = chartRect.top + (chartRect.height * i / 3);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final double maxRevenue = points
        .map((DailyRevenuePoint point) => point.revenue)
        .fold<double>(0, (double a, double b) => a > b ? a : b);
    final double safeMax = maxRevenue <= 0 ? 1 : maxRevenue;

    final List<Offset> chartPoints = <Offset>[];
    for (int i = 0; i < points.length; i += 1) {
      final double x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + (chartRect.width * i / (points.length - 1));
      final double y = chartRect.bottom -
          (chartRect.height * (points[i].revenue / safeMax));
      chartPoints.add(Offset(x, y));
    }

    final Path areaPath = Path()..moveTo(chartPoints.first.dx, chartRect.bottom);
    for (final Offset point in chartPoints) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath
      ..lineTo(chartPoints.last.dx, chartRect.bottom)
      ..close();

    final Paint areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x663B82F6), Color(0x0D3B82F6)],
      ).createShader(chartRect);
    canvas.drawPath(areaPath, areaPaint);

    final Paint linePaint = Paint()
      ..color = const Color(0xFF0B5FA5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Path linePath = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (int i = 1; i < chartPoints.length; i += 1) {
      linePath.lineTo(chartPoints[i].dx, chartPoints[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final int safeSelectedIndex = selectedIndex.clamp(0, points.length - 1);
    final Offset selectedPoint = chartPoints[safeSelectedIndex];
    final Paint selectedLinePaint = Paint()
      ..color = const Color(0x330B5FA5)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(selectedPoint.dx, chartRect.top),
      Offset(selectedPoint.dx, chartRect.bottom),
      selectedLinePaint,
    );

    final Paint dotPaint = Paint()..color = const Color(0xFF0B5FA5);
    final Paint haloPaint = Paint()..color = const Color(0x330B5FA5);
    for (int i = 0; i < chartPoints.length; i += 1) {
      final bool isSelected = i == safeSelectedIndex;
      if (isSelected) {
        canvas.drawCircle(chartPoints[i], 11, haloPaint);
      }
      canvas.drawCircle(chartPoints[i], isSelected ? 5 : 3.5, dotPaint);
      if (isSelected) {
        canvas.drawCircle(
          chartPoints[i],
          3,
          Paint()..color = Colors.white,
        );
      }
    }

    final TextPainter startLabel = TextPainter(
      text: TextSpan(
        text: points.first.shortLabel,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      textDirection: textDirection,
    )..layout();
    startLabel.paint(canvas, Offset(chartRect.left, size.height - bottomPad + 8));

    final TextPainter endLabel = TextPainter(
      text: TextSpan(
        text: points.last.shortLabel,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      textDirection: textDirection,
    )..layout();
    endLabel.paint(
      canvas,
      Offset(chartRect.right - endLabel.width, size.height - bottomPad + 8),
    );

    final TextPainter maxLabel = TextPainter(
      text: TextSpan(
        text: 'Rs ${safeMax.toStringAsFixed(0)}',
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      textDirection: textDirection,
    )..layout();
    maxLabel.paint(canvas, Offset(chartRect.left, 0));
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.textDirection != textDirection;
  }
}

class AnnouncementsManagementPage extends StatelessWidget {
  const AnnouncementsManagementPage({
    super.key,
    required this.adminName,
    required this.repo,
  });

  final String adminName;
  final BillingRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<AnnouncementRecord>>(
        stream: repo.streamAnnouncements(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AnnouncementRecord>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<AnnouncementRecord> items =
              snapshot.data ?? <AnnouncementRecord>[];
          if (items.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final AnnouncementRecord item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: item.isActive,
                        onChanged: (bool value) async {
                          await repo.upsertAnnouncement(
                            docId: item.docId,
                            title: item.title,
                            message: item.message,
                            isActive: value,
                            isPinned: item.isPinned,
                            adminName: adminName,
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () => _openEditor(context, current: item),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () async {
                          await repo.deleteAnnouncement(item.docId);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    AnnouncementRecord? current,
  }) async {
    final TextEditingController titleCtrl = TextEditingController(
      text: current?.title ?? '',
    );
    final TextEditingController messageCtrl = TextEditingController(
      text: current?.message ?? '',
    );
    bool active = current?.isActive ?? true;
    bool pinned = current?.isPinned ?? false;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'New Announcement' : 'Edit Announcement'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (String? value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: messageCtrl,
                        decoration: const InputDecoration(labelText: 'Message'),
                        maxLines: 3,
                        validator: (String? value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: active,
                        onChanged: (bool v) => setDialogState(() => active = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pinned'),
                        value: pinned,
                        onChanged: (bool v) => setDialogState(() => pinned = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save == true) {
      await repo.upsertAnnouncement(
        docId: current?.docId,
        title: titleCtrl.text.trim(),
        message: messageCtrl.text.trim(),
        isActive: active,
        isPinned: pinned,
        adminName: adminName,
      );
    }

    titleCtrl.dispose();
    messageCtrl.dispose();
  }
}

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({
    super.key,
    required this.adminName,
    required this.repo,
  });

  final String adminName;
  final BillingRepository repo;

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _supportPhoneCtrl = TextEditingController();
  final TextEditingController _supportEmailCtrl = TextEditingController();
  final TextEditingController _localityCtrl = TextEditingController();
  final TextEditingController _addressLine1Ctrl = TextEditingController();
  final TextEditingController _addressLine2Ctrl = TextEditingController();
  final TextEditingController _addressLine3Ctrl = TextEditingController();
  final TextEditingController _gstinCtrl = TextEditingController();
  final TextEditingController _gstPercentCtrl = TextEditingController();
  final TextEditingController _prefixCtrl = TextEditingController();
  bool _gstEnabled = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _supportEmailCtrl.dispose();
    _localityCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    _addressLine3Ctrl.dispose();
    _gstinCtrl.dispose();
    _gstPercentCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Settings')),
      body: StreamBuilder<BusinessProfile>(
        stream: widget.repo.streamBusinessProfile(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<BusinessProfile> businessSnapshot,
            ) {
              return StreamBuilder<BillingConfig>(
                stream: widget.repo.streamBillingConfig(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<BillingConfig> billingSnapshot,
                    ) {
                      if (businessSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          billingSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !_loaded) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final BusinessProfile profile =
                          businessSnapshot.data ?? BusinessProfile.defaults();
                      final BillingConfig config =
                          billingSnapshot.data ?? BillingConfig.defaults();

                      if (!_loaded) {
                        _companyCtrl.text = profile.companyName;
                        _supportPhoneCtrl.text = profile.supportPhone;
                        _supportEmailCtrl.text = profile.supportEmail;
                        _localityCtrl.text = profile.locality;
                        _addressLine1Ctrl.text = profile.addressLine1;
                        _addressLine2Ctrl.text = profile.addressLine2;
                        _addressLine3Ctrl.text = profile.addressLine3;
                        _gstinCtrl.text = profile.gstin;
                        _gstPercentCtrl.text =
                            (config.gstRate * 100).toStringAsFixed(2);
                        _prefixCtrl.text = config.invoicePrefix;
                        _gstEnabled = config.gstEnabled;
                        _loaded = true;
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Business Profile',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Website and invoice display details. Changes here should be reflected across customer-facing screens.',
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _companyCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Company display name',
                                          ),
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _supportPhoneCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Support phone',
                                          ),
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _supportEmailCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Support email',
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _localityCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Locality / city label',
                                          ),
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _addressLine1Ctrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Address line 1',
                                          ),
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _addressLine2Ctrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Address line 2',
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _addressLine3Ctrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Address line 3',
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _gstinCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'GSTIN',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Billing Rules',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Used for checkout summaries, order totals, and PDF bill generation.',
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _prefixCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Invoice prefix',
                                            hintText: 'Example: BILL',
                                          ),
                                          validator: _required,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _gstPercentCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'GST %',
                                            hintText: 'Example: 18',
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            final double? gst =
                                                double.tryParse(value.trim());
                                            if (gst == null ||
                                                gst < 0 ||
                                                gst > 100) {
                                              return 'Enter a number from 0 to 100';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                            'Enable GST in bill totals',
                                          ),
                                          value: _gstEnabled,
                                          onChanged: (bool value) => setState(
                                            () => _gstEnabled = value,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _save,
                                    child: Text(
                                      _saving
                                          ? 'Saving...'
                                          : 'Save Settings',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
              );
            },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final double gstPercent = double.tryParse(_gstPercentCtrl.text.trim()) ?? 0;
      await widget.repo.saveBusinessProfile(
        profile: BusinessProfile(
          companyName: _companyCtrl.text.trim(),
          supportPhone: _supportPhoneCtrl.text.trim(),
          supportEmail: _supportEmailCtrl.text.trim(),
          locality: _localityCtrl.text.trim(),
          addressLine1: _addressLine1Ctrl.text.trim(),
          addressLine2: _addressLine2Ctrl.text.trim(),
          addressLine3: _addressLine3Ctrl.text.trim(),
          gstin: _gstinCtrl.text.trim(),
        ),
        adminName: widget.adminName,
      );
      await widget.repo.saveBillingConfig(
        config: BillingConfig(
          companyName: _companyCtrl.text.trim(),
          supportPhone: _supportPhoneCtrl.text.trim(),
          invoicePrefix: _prefixCtrl.text.trim().toUpperCase(),
          gstRate: gstPercent / 100,
          gstEnabled: _gstEnabled,
        ),
        adminName: widget.adminName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;
}

class BillsManagementPage extends StatelessWidget {
  const BillsManagementPage({
    super.key,
    required this.adminName,
    required this.repo,
  });

  final String adminName;
  final BillingRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bills')),
      body: StreamBuilder<List<BillRecord>>(
        stream: repo.streamAllBills(),
        initialData: repo.cachedAllBills,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<BillRecord>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<BillRecord> bills = snapshot.data ?? <BillRecord>[];
          if (bills.isEmpty) {
            return const Center(child: Text('No bills found.'));
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (BuildContext context, int index) {
              final BillRecord bill = bills[index];

              return Card(
                child: ListTile(
                  title: Text('${bill.billNumber} - ${bill.customerName}'),
                  subtitle: Text(
                    'Source: ${bill.source} | ${_titleCase(bill.status)}${bill.createdAt == null ? '' : ' | ${_formatDateTime(bill.createdAt)}'}',
                  ),
                  trailing: Text('Rs ${bill.total.toStringAsFixed(2)}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EditBillPage(
                        adminName: adminName,
                        repo: repo,
                        billDocId: bill.docId,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditBillPage extends StatefulWidget {
  const EditBillPage({
    super.key,
    required this.adminName,
    required this.repo,
    required this.billDocId,
  });

  final String adminName;
  final BillingRepository repo;
  final String billDocId;

  @override
  State<EditBillPage> createState() => _EditBillPageState();
}

class _EditBillPageState extends State<EditBillPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late final Future<void> _initFuture = _load();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _paymentCtrl = TextEditingController();
  final TextEditingController _statusCtrl = TextEditingController();

  List<LineEditor> _lines = <LineEditor>[LineEditor()];
  String _billNumber = '';
  String _userId = '';
  String _companyName = 'A1 Water Tech';
  String _supportPhone = '';
  double _gstRate = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _invoiceCtrl.dispose();
    _paymentCtrl.dispose();
    _statusCtrl.dispose();
    for (final LineEditor l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final Map<String, dynamic> data = await widget.repo.fetchBill(
      widget.billDocId,
    );
    _billNumber = _str(data['billNumber'], fallback: widget.billDocId);
    _userId = _str(data['userId']);
    _companyName = _str(data['companyName'], fallback: 'A1 Water Tech');
    _supportPhone = _str(data['supportPhone']);
    _statusCtrl.text = _str(data['status'], fallback: 'confirmed');
    final Map<String, dynamic> billing = _map(data['billing']);
    _gstRate = _dbl(billing['gstRate']);

    final Map<String, dynamic> customer = _map(data['customer']);
    _nameCtrl.text = _str(customer['fullName']);
    _phoneCtrl.text = _str(customer['phone']);
    _cityCtrl.text = _str(customer['city']);
    _addressCtrl.text = _str(customer['address']);
    _invoiceCtrl.text = _str(customer['invoiceType'], fallback: 'GST Invoice');
    _paymentCtrl.text = _str(customer['paymentMethod'], fallback: 'UPI');

    final List<dynamic> rawItems = (data['items'] is List) ? data['items'] as List : <dynamic>[];
    for (final LineEditor l in _lines) {
      l.dispose();
    }
    _lines = rawItems.isEmpty ? <LineEditor>[LineEditor()] : rawItems.map((dynamic raw) {
      final Map<String, dynamic> item = _map(raw);
      return LineEditor(
        name: _str(item['name']),
        qty: _int(item['qty'], fallback: 1).toString(),
        price: _dbl(item['price']).toStringAsFixed(2),
      );
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
      for (final LineEditor line in _lines) {
        final String name = line.name.text.trim();
        if (name.isEmpty) continue;
        items.add(<String, dynamic>{
          'name': name,
          'qty': int.tryParse(line.qty.text.trim()) ?? 1,
          'price': double.tryParse(line.price.text.trim()) ?? 0,
        });
      }

      final double subtotal = items.fold<double>(0, (double t, Map<String, dynamic> i) {
        final int qty = int.tryParse((i['qty'] ?? 0).toString()) ?? 0;
        final double price = double.tryParse((i['price'] ?? 0).toString()) ?? 0;
        return t + (qty * price);
      });

      final Map<String, dynamic> payload = <String, dynamic>{
        'customer': <String, dynamic>{
          'fullName': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'invoiceType': _invoiceCtrl.text.trim(),
          'paymentMethod': _paymentCtrl.text.trim(),
        },
        'items': items,
        'subtotal': subtotal,
        'billing': <String, dynamic>{'gstRate': _gstRate, 'gstAmount': subtotal * _gstRate},
        'total': subtotal + (subtotal * _gstRate),
        'status': _statusCtrl.text.trim(),
        'updatedBy': widget.adminName,
      };

      await widget.repo.updateBill(
        billId: widget.billDocId,
        payload: payload,
        userId: _userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill updated.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sharePdf() async {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final LineEditor line in _lines) {
      final String name = line.name.text.trim();
      if (name.isEmpty) continue;
      items.add(<String, dynamic>{
        'name': name,
        'qty': int.tryParse(line.qty.text.trim()) ?? 1,
        'price': double.tryParse(line.price.text.trim()) ?? 0,
      });
    }
    final double subtotal = items.fold<double>(0, (double t, Map<String, dynamic> i) {
      final int qty = int.tryParse((i['qty'] ?? 0).toString()) ?? 0;
      final double price = double.tryParse((i['price'] ?? 0).toString()) ?? 0;
      return t + (qty * price);
    });

    final Uint8List bytes = await buildBillingPdf(
      billNumber: _billNumber.isEmpty ? widget.billDocId : _billNumber,
      generatedBy: widget.adminName,
      companyName: _companyName,
      supportPhone: _supportPhone,
      customerName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      invoiceType: _invoiceCtrl.text.trim(),
      paymentMethod: _paymentCtrl.text.trim(),
      items: items,
      subtotal: subtotal,
      gstRate: _gstRate,
      gstAmount: subtotal * _gstRate,
      total: subtotal + (subtotal * _gstRate),
    );

    final String filename = '${_billNumber.isEmpty ? widget.billDocId : _billNumber}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bill')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _billNumber.isEmpty ? widget.billDocId : _billNumber,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _statusCtrl,
                              decoration: const InputDecoration(labelText: 'Status'),
                              validator: _required,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'Customer name'),
                              validator: _required,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              validator: _required,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(labelText: 'City'),
                              validator: _required,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(labelText: 'Address'),
                              validator: _required,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _invoiceCtrl,
                              decoration: const InputDecoration(labelText: 'Invoice type'),
                              validator: _required,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _paymentCtrl,
                              decoration: const InputDecoration(labelText: 'Payment method'),
                              validator: _required,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._buildLineEditors(context),
              Row(
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed: () => setState(() => _lines.add(LineEditor())),
                    child: const Text('Add item'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _sharePdf,
                    child: const Text('Download / Share PDF'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  List<Widget> _buildLineEditors(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < _lines.length; i += 1) {
      rows.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _lines[i].name,
                    decoration: const InputDecoration(labelText: 'Item'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lines[i].qty,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lines[i].price,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: _lines.length == 1
                      ? null
                      : () => setState(() {
                            _lines[i].dispose();
                            _lines.removeAt(i);
                          }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return rows;
  }
}

class OrderRecord {
  const OrderRecord({
    required this.docId,
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.city,
    required this.address,
    required this.invoiceType,
    required this.paymentMethod,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String docId;
  final String orderId;
  final String userId;
  final String customerName;
  final String phone;
  final String city;
  final String address;
  final String invoiceType;
  final String paymentMethod;
  final List<BillLine> items;
  final double total;
  final String status;
  final DateTime? createdAt;

  static OrderRecord fromMap(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    final Map<String, dynamic> customer = _map(data['customer']);
    final Map<String, dynamic> address = _map(data['address']);
    final List<BillLine> items = _items(data['items']);
    return OrderRecord(
      docId: docId,
      orderId: _str(data['orderId'], fallback: docId),
      userId: _str(data['userId']),
      customerName: _str(customer['fullName']),
      phone: _str(customer['phone']),
      city: _str(
        customer['city'],
        fallback: _str(address['city']),
      ),
      address: _str(
        customer['address'],
        fallback: _str(address['address']),
      ),
      invoiceType: _str(customer['invoiceType'], fallback: 'GST Invoice'),
      paymentMethod: _str(customer['paymentMethod'], fallback: 'UPI'),
      items: items,
      total: _dbl(data['total'], fallback: _sum(items)),
      status: _str(data['status'], fallback: 'pending'),
      createdAt: _date(data['createdAt']),
    );
  }
}

class BillRecord {
  const BillRecord({
    required this.docId,
    required this.billNumber,
    required this.customerName,
    required this.source,
    required this.total,
    required this.status,
    required this.createdAt,
  });
  final String docId;
  final String billNumber;
  final String customerName;
  final String source;
  final double total;
  final String status;
  final DateTime? createdAt;

  static BillRecord fromMap(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    final Map<String, dynamic> customer = _map(data['customer']);
    return BillRecord(
      docId: docId,
      billNumber: _str(data['billNumber'], fallback: docId),
      customerName: _str(customer['fullName'], fallback: 'Unknown'),
      source: _str(data['source'], fallback: 'manual'),
      total: _dbl(data['total']),
      status: _str(data['status'], fallback: 'confirmed'),
      createdAt: _date(data['createdAt']),
    );
  }
}

class ServiceBookingRecord {
  const ServiceBookingRecord({
    required this.bookingId,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.city,
    required this.address,
    required this.serviceType,
    required this.date,
    required this.slot,
    required this.status,
    required this.createdAt,
  });

  final String bookingId;
  final String userId;
  final String customerName;
  final String phone;
  final String email;
  final String city;
  final String address;
  final String serviceType;
  final String date;
  final String slot;
  final String status;
  final DateTime? createdAt;

  String get dateLabel => date.isEmpty ? 'No date' : date;

  static ServiceBookingRecord fromMap(
    Map<String, dynamic> data, {
    required String bookingId,
  }) {
    final Map<String, dynamic> addressSnapshot = _map(data['addressSnapshot']);
    return ServiceBookingRecord(
      bookingId: bookingId,
      userId: _str(data['userId']),
      customerName: _str(
        data['name'],
        fallback: _str(data['customerName'], fallback: 'Unknown'),
      ),
      phone: _str(data['phone'], fallback: _str(addressSnapshot['phone'])),
      email: _str(data['email'], fallback: _str(addressSnapshot['email'])),
      city: _str(data['city'], fallback: _str(addressSnapshot['city'])),
      address: _str(
        data['address'],
        fallback: _str(addressSnapshot['address']),
      ),
      serviceType: _str(
        data['serviceType'],
        fallback: _str(data['serviceName'], fallback: 'Service'),
      ),
      date: _str(data['date']),
      slot: _str(data['slot'], fallback: _str(data['time'])),
      status: _str(data['status'], fallback: 'scheduled'),
      createdAt: _date(data['createdAt']),
    );
  }
}

class FeedbackRecord {
  const FeedbackRecord({
    required this.docId,
    required this.customerName,
    required this.phone,
    required this.orderId,
    required this.message,
    required this.rating,
    required this.status,
    required this.adminResponse,
    required this.createdAt,
  });

  final String docId;
  final String customerName;
  final String phone;
  final String orderId;
  final String message;
  final int rating;
  final String status;
  final String adminResponse;
  final DateTime? createdAt;

  static FeedbackRecord fromMap(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    final Map<String, dynamic> customer = _map(data['customer']);
    return FeedbackRecord(
      docId: docId,
      customerName: _str(
        data['customerName'],
        fallback: _str(
          data['name'],
          fallback: _str(customer['fullName'], fallback: 'Unknown'),
        ),
      ),
      phone: _str(data['phone'], fallback: _str(customer['phone'])),
      orderId: _str(data['orderId']),
      message: _str(
        data['message'],
        fallback: _str(
          data['feedback'],
          fallback: _str(data['comment'], fallback: _str(data['text'])),
        ),
      ),
      rating: _int(
        data['rating'],
        fallback: _int(data['stars']),
      ),
      status: _normalizeFeedbackStatus(_str(data['status'], fallback: 'open')),
      adminResponse: _str(
        data['adminResponse'],
        fallback: _str(data['response']),
      ),
      createdAt: _date(data['createdAt']),
    );
  }
}

class AnnouncementRecord {
  const AnnouncementRecord({
    required this.docId,
    required this.title,
    required this.message,
    required this.isActive,
    required this.isPinned,
    required this.createdAt,
  });

  final String docId;
  final String title;
  final String message;
  final bool isActive;
  final bool isPinned;
  final DateTime? createdAt;

  static AnnouncementRecord fromMap(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    return AnnouncementRecord(
      docId: docId,
      title: _str(data['title'], fallback: 'Announcement'),
      message: _str(data['message']),
      isActive: data['isActive'] == true,
      isPinned: data['isPinned'] == true,
      createdAt: _date(data['createdAt']),
    );
  }
}

class BillingConfig {
  const BillingConfig({
    required this.companyName,
    required this.supportPhone,
    required this.invoicePrefix,
    required this.gstRate,
    required this.gstEnabled,
  });

  final String companyName;
  final String supportPhone;
  final String invoicePrefix;
  final double gstRate;
  final bool gstEnabled;

  factory BillingConfig.defaults() {
    return const BillingConfig(
      companyName: 'A1 Water Tech',
      supportPhone: '',
      invoicePrefix: 'BILL',
      gstRate: 0,
      gstEnabled: false,
    );
  }

  factory BillingConfig.fromMap(Map<String, dynamic> data) {
    return BillingConfig(
      companyName: _str(data['companyName'], fallback: 'A1 Water Tech'),
      supportPhone: _str(data['supportPhone']),
      invoicePrefix: _str(data['invoicePrefix'], fallback: 'BILL'),
      gstRate: _dbl(data['gstRate']),
      gstEnabled: data['gstEnabled'] == true,
    );
  }
}

class BusinessProfile {
  const BusinessProfile({
    required this.companyName,
    required this.supportPhone,
    required this.supportEmail,
    required this.locality,
    required this.addressLine1,
    required this.addressLine2,
    required this.addressLine3,
    required this.gstin,
  });

  final String companyName;
  final String supportPhone;
  final String supportEmail;
  final String locality;
  final String addressLine1;
  final String addressLine2;
  final String addressLine3;
  final String gstin;

  factory BusinessProfile.defaults() {
    return const BusinessProfile(
      companyName: 'A1 Water Tech',
      supportPhone: '+91 8778308119',
      supportEmail: 'thinakarans12345@gmail.com',
      locality: 'Gobichettipalayam, Tamil Nadu',
      addressLine1: 'G.K.M Gowtham Complex, Opp. HP Bunk',
      addressLine2: 'Sathy-Athani Main Road, Kalipatti',
      addressLine3: 'Gobichettipalayam - 638505',
      gstin: '33CWHPH8901N1Z6',
    );
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> data) {
    return BusinessProfile(
      companyName: _str(data['companyName'], fallback: 'A1 Water Tech'),
      supportPhone: _str(
        data['supportPhone'],
        fallback: '+91 8778308119',
      ),
      supportEmail: _str(
        data['supportEmail'],
        fallback: 'thinakarans12345@gmail.com',
      ),
      locality: _str(
        data['locality'],
        fallback: 'Gobichettipalayam, Tamil Nadu',
      ),
      addressLine1: _str(
        data['addressLine1'],
        fallback: 'G.K.M Gowtham Complex, Opp. HP Bunk',
      ),
      addressLine2: _str(
        data['addressLine2'],
        fallback: 'Sathy-Athani Main Road, Kalipatti',
      ),
      addressLine3: _str(
        data['addressLine3'],
        fallback: 'Gobichettipalayam - 638505',
      ),
      gstin: _str(data['gstin'], fallback: '33CWHPH8901N1Z6'),
    );
  }
}

class ItemPerformance {
  const ItemPerformance({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final double revenue;
}

class DailyRevenuePoint {
  const DailyRevenuePoint({
    required this.date,
    required this.revenue,
    required this.billsCount,
  });

  final DateTime date;
  final double revenue;
  final int billsCount;

  String get shortLabel {
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String get label {
    final String yyyy = date.year.toString().padLeft(4, '0');
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String get shortWeekday {
    const List<String> weekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return weekdays[date.weekday - 1];
  }

  bool get isToday {
    final DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class AdminMetrics {
  const AdminMetrics({
    required this.ordersCount,
    required this.billsCount,
    required this.billsInRange,
    required this.salesCount,
    required this.salesCountInRange,
    required this.bookingsCount,
    required this.pendingOrders,
    required this.activeProducts,
    required this.activeServices,
    required this.openFeedbackCount,
    required this.totalRevenue,
    required this.revenueInRange,
    required this.topItems,
    required this.dailyRevenue,
  });

  final int ordersCount;
  final int billsCount;
  final int billsInRange;
  final int salesCount;
  final int salesCountInRange;
  final int bookingsCount;
  final int pendingOrders;
  final int activeProducts;
  final int activeServices;
  final int openFeedbackCount;
  final double totalRevenue;
  final double revenueInRange;
  final List<ItemPerformance> topItems;
  final List<DailyRevenuePoint> dailyRevenue;

  double get averageDailyRevenue =>
      dailyRevenue.isEmpty ? 0 : revenueInRange / dailyRevenue.length;

  double get maxTopItemRevenue => topItems.isEmpty
      ? 0
      : topItems
          .map((ItemPerformance item) => item.revenue)
          .reduce((double a, double b) => a > b ? a : b);

  factory AdminMetrics.empty() {
    return const AdminMetrics(
      ordersCount: 0,
      billsCount: 0,
      billsInRange: 0,
      salesCount: 0,
      salesCountInRange: 0,
      bookingsCount: 0,
      pendingOrders: 0,
      activeProducts: 0,
      activeServices: 0,
      openFeedbackCount: 0,
      totalRevenue: 0,
      revenueInRange: 0,
      topItems: <ItemPerformance>[],
      dailyRevenue: <DailyRevenuePoint>[],
    );
  }
}

class CatalogItemRecord {
  const CatalogItemRecord({
    required this.docId,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  final String docId;
  final String type;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  static CatalogItemRecord fromMap(
    Map<String, dynamic> data, {
    required String docId,
    required String fallbackType,
  }) {
    return CatalogItemRecord(
      docId: docId,
      type: fallbackType,
      name: _str(data['name'], fallback: 'Unnamed'),
      description: _str(data['description']),
      price: _dbl(data['price']),
      imageUrl: _str(data['imageUrl']),
    );
  }
}

class BillDraft {
  const BillDraft({
    required this.source,
    required this.sourceOrderDocId,
    required this.sourceOrderId,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.city,
    required this.address,
    required this.invoiceType,
    required this.paymentMethod,
    required this.items,
  });

  final String source;
  final String sourceOrderDocId;
  final String sourceOrderId;
  final String userId;
  final String customerName;
  final String phone;
  final String city;
  final String address;
  final String invoiceType;
  final String paymentMethod;
  final List<BillLine> items;

  double get subtotal => _sum(items);

  BillDraft copyWith({
    String? customerName,
    String? phone,
    String? city,
    String? address,
    String? invoiceType,
    String? paymentMethod,
    List<BillLine>? items,
  }) {
    return BillDraft(
      source: source,
      sourceOrderDocId: sourceOrderDocId,
      sourceOrderId: sourceOrderId,
      userId: userId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      invoiceType: invoiceType ?? this.invoiceType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
    );
  }

  factory BillDraft.empty() {
    return const BillDraft(
      source: 'manual',
      sourceOrderDocId: '',
      sourceOrderId: '',
      userId: '',
      customerName: '',
      phone: '',
      city: '',
      address: '',
      invoiceType: 'GST Invoice',
      paymentMethod: 'UPI',
      items: <BillLine>[],
    );
  }

  factory BillDraft.fromOrder(OrderRecord order) {
    return BillDraft(
      source: 'automatic',
      sourceOrderDocId: order.docId,
      sourceOrderId: order.orderId,
      userId: order.userId,
      customerName: order.customerName,
      phone: order.phone,
      city: order.city,
      address: order.address,
      invoiceType: order.invoiceType,
      paymentMethod: order.paymentMethod,
      items: order.items,
    );
  }
}

class BillLine {
  const BillLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final int quantity;
  final double unitPrice;
  double get lineTotal => quantity * unitPrice;
}

class LineEditor {
  LineEditor({String name = '', String qty = '1', String price = ''})
    : name = TextEditingController(text: name),
      qty = TextEditingController(text: qty),
      price = TextEditingController(text: price);

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

List<BillLine> _items(dynamic value) {
  if (value is! List) return <BillLine>[];
  return value.map((dynamic raw) {
    final Map<String, dynamic> item = _map(raw);
    return BillLine(
      name: _str(item['name'], fallback: _str(item['productId'], fallback: 'Item')),
      quantity: _int(
        item['qty'],
        fallback: _int(item['quantity'], fallback: 1),
      ),
      unitPrice: _dbl(item['unitPrice'], fallback: _dbl(item['price'])),
    );
  }).toList();
}

DateTime? _date(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Unknown time';
  final DateTime local = value.toLocal();
  final String yyyy = local.year.toString().padLeft(4, '0');
  final String mm = local.month.toString().padLeft(2, '0');
  final String dd = local.day.toString().padLeft(2, '0');
  final String hh = local.hour.toString().padLeft(2, '0');
  final String min = local.minute.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd $hh:$min';
}

String _normalizeFeedbackStatus(String value) {
  final String normalized = value.trim().toLowerCase().replaceAll(' ', '_');
  switch (normalized) {
    case 'resolved':
      return 'resolved';
    case 'in_progress':
    case 'inprogress':
      return 'in_progress';
    default:
      return 'open';
  }
}

String _titleCase(String value) {
  final List<String> words = value
      .trim()
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return '';
  }
  return words
      .map(
        (String word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _str(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  final String s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

int _int(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double _dbl(dynamic v, {double fallback = 0}) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

double _sum(List<BillLine> lines) {
  return lines.fold<double>(0, (double t, BillLine i) => t + i.lineTotal);
}
