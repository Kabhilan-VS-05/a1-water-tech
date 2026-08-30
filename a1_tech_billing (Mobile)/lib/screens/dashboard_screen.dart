import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'settings/business_info_screen.dart';
import 'settings/settings_screen.dart';
import 'terms/terms_screen.dart';
import 'customers/customers_screen.dart';
import 'catalog/catalog_screen.dart';
import 'quotation/quotation_screen.dart';
import 'billing/manual_billing_screen.dart';
import 'billing/billing_dashboard_screen.dart';
import 'purchase_order/purchase_order_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  String _businessName = 'A1 water';

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    final name = await _db.getSetting('companyName');
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _businessName = name);
    }
  }

  void _nav(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadBusinessName());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _businessName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurface, size: 26),
                    onPressed: () => _nav(const SettingsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Manage Section
              Text(
                'Manage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildManageItem(
                    icon: Icons.apartment_rounded,
                    label: 'BUSINESS',
                    onTap: () => _nav(const BusinessInfoScreen()),
                  ),
                  _buildManageItem(
                    icon: Icons.person_rounded,
                    label: 'CUSTOMER',
                    onTap: () => _nav(const CustomersScreen()),
                  ),
                  _buildManageItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'PRODUCT',
                    onTap: () => _nav(const CatalogScreen()),
                  ),
                  _buildManageItem(
                    icon: Icons.article_rounded,
                    label: 'TERMS',
                    onTap: () => _nav(const TermsConditionsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Discover Section
              Text(
                'Discover',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),

              // 2-Column Grid of Action Cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  _buildDiscoverCard(
                    icon: Icons.note_add_outlined,
                    title: 'Make Quotation',
                    subtitle: 'Create a new quotation',
                    onTap: () => _nav(const CreateQuotationScreen()),
                  ),
                  _buildDiscoverCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Quotation List',
                    subtitle: 'Manage all quotations',
                    onTap: () => _nav(const QuotationScreen()),
                  ),
                  _buildDiscoverCard(
                    icon: Icons.post_add_rounded,
                    title: 'Make Invoice',
                    subtitle: 'Create a new invoice',
                    onTap: () => _nav(const ManualBillingScreen()),
                  ),
                  _buildDiscoverCard(
                    icon: Icons.format_list_bulleted_rounded,
                    title: 'Invoice List',
                    subtitle: 'Manage all invoices',
                    onTap: () => _nav(const BillingDashboardScreen()),
                  ),
                  _buildDiscoverCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Purchase Order',
                    subtitle: 'Manage all purchase orders',
                    onTap: () => _nav(const PurchaseOrderScreen()),
                  ),
                  _buildDiscoverCard(
                    icon: Icons.tune_rounded,
                    title: 'Settings',
                    subtitle: 'Manage app settings',
                    onTap: () => _nav(const SettingsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDiscoverCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
