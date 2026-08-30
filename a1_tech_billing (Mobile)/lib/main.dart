import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_layout_screen.dart';
import 'screens/login_screen.dart';
import 'screens/billing/manual_billing_screen.dart';
import 'screens/billing/bill_history_screen.dart';
import 'screens/billing/auto_billing_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'package:workmanager/workmanager.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/logger_service.dart';
import 'config/app_config.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService().initialize();
      
      // Initialize and restore auth session in the background isolate
      final authService = AuthService();
      await authService.initialize();
      await authService.restoreSession();

      final syncService = SyncService();
      // Only do a quick check to avoid heavy DB ops if not needed
      await syncService.initialize();
      await syncService.syncAll();
    } catch (e) {
      AppLogger.error("Background sync error: $e", tag: 'BackgroundSync');
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
      await NotificationService().requestPermission();
      
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      
      Workmanager().registerPeriodicTask(
        "1",
        "backgroundSyncTask",
        frequency: Duration(minutes: AppConfig.backgroundSyncIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      AppLogger.info("Background sync scheduled for every ${AppConfig.backgroundSyncIntervalMinutes} minutes", tag: 'BackgroundSync');
    } catch (e) {
      AppLogger.error("Failed to initialize background services: $e", tag: 'Main');
    }
  }
  
  runApp(const A1BillingApp());
}

class A1BillingApp extends StatelessWidget {
  const A1BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'A1 FlowSyn',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            home: appProvider.isLoading 
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : (appProvider.isAuthenticated ? const MainLayoutScreen() : const LoginScreen()),
            routes: {
              '/billing/manual': (context) => const ManualBillingScreen(),
              '/billing/history': (context) => const BillHistoryScreen(),
              '/billing/auto': (context) => const AutoBillingScreen(),
              '/catalog': (context) => const CatalogScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
