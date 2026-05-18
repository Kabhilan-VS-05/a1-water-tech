import 'package:flutter/material.dart';
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService().initialize();
      final syncService = SyncService();
      // Only do a quick check to avoid heavy DB ops if not needed
      await syncService.initialize();
      await syncService.syncAll();
    } catch (e) {
      print("Background sync error: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await NotificationService().initialize();
    
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Register background task to run every 15 minutes
    Workmanager().registerPeriodicTask(
      "1",
      "backgroundSyncTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } catch (e) {
    debugPrint("Failed to initialize background services: $e");
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
