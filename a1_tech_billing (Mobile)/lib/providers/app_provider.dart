import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    // Save to DB
    _db.setSetting('themeMode', mode.toString());
    notifyListeners();
  }

  final DatabaseService _db = DatabaseService();
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index, {int? ordersTabIndex}) {
    _currentTabIndex = index;
    if (ordersTabIndex != null) {
      _ordersTabIndex = ordersTabIndex;
    }
    notifyListeners();
  }

  int _ordersTabIndex = 0;
  int get ordersTabIndex => _ordersTabIndex;

  void setOrdersTabIndex(int index) {
    _ordersTabIndex = index;
    notifyListeners();
  }

  bool get isAuthenticated => _authService.isAuthenticated;

  int _pendingNotificationCount = 0;
  int get pendingNotificationCount => _pendingNotificationCount;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      await _authService.restoreSession();
      await _syncService.initialize();
      
      // Load theme
      final savedTheme = await _db.getSetting('themeMode');
      if (savedTheme != null) {
        if (savedTheme == 'ThemeMode.light') _themeMode = ThemeMode.light;
        if (savedTheme == 'ThemeMode.dark') _themeMode = ThemeMode.dark;
        if (savedTheme == 'ThemeMode.system') _themeMode = ThemeMode.system;
      }

      // Listen for notifications
      _syncService.notificationStream.listen((count) {
        _pendingNotificationCount = count;
        notifyListeners();
      });

      // Listen for notification taps to switch to Online Orders tab
      NotificationService().onTapStream.listen((payload) {
        if (payload == 'orders') {
          setTabIndex(1, ordersTabIndex: 0);
        }
      });
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.signIn(username, password);
      _setLoading(false);
      if (result == AuthResult.success) {
        // Trigger a background sync immediately so the database is populated
        _syncService.syncAll();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }
}
