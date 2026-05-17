import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'orders/orders_screen.dart';
import 'customers/customers_screen.dart';
import 'catalog/catalog_screen.dart';
import 'billing/billing_dashboard_screen.dart'; // We will create this

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    OrdersScreen(),
    BillingDashboardScreen(),
    CustomersScreen(),
    CatalogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final int currentIndex = appProvider.currentTabIndex;

    return Scaffold(
      appBar: AppBar(
        leading: currentIndex != 0 ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => appProvider.setTabIndex(0),
        ) : null,
        title: Text(
          currentIndex == 0 ? 'A1 Water Tech' : 
          currentIndex == 1 ? 'Online Orders' : 
          currentIndex == 2 ? 'Billing Center' : 
          currentIndex == 3 ? 'Customers' : 'Catalog Management',
          style: const TextStyle(fontWeight: FontWeight.w800)
        ),
        actions: [
          if (currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: () {
                context.read<AppProvider>().logout();
              },
            )
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => appProvider.setTabIndex(index),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(appProvider.pendingNotificationCount.toString()),
                isLabelVisible: appProvider.pendingNotificationCount > 0,
                backgroundColor: AppTheme.errorColor,
                child: const Icon(Icons.local_shipping_rounded),
              ), 
              label: 'Orders',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Billing'),
            const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Customers'),
            const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Catalog'),
          ],
        ),
      ),
    );
  }
}
