import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';

class BillingDashboardScreen extends StatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  int _billCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getDashboardStats();
    if (mounted) {
      setState(() {
        _billCount = stats['totalBills'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Center', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Create and manage invoices', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 32),
            
            // Manual Billing Card
            _BillingActionCard(
              title: 'Create Manual Bill',
              description: 'Generate an invoice for walk-in customers or custom orders.',
              icon: Icons.receipt_rounded,
              color: AppTheme.accentColor,
              onTap: () => Navigator.pushNamed(context, '/billing/manual'),
            ),
            
            const SizedBox(height: 16),
            
            // Generate from Orders Card
            _BillingActionCard(
              title: 'Generate from Orders',
              description: 'Convert confirmed online orders directly into invoices.',
              icon: Icons.local_shipping_rounded,
              color: AppTheme.secondaryColor,
              onTap: () {
                context.read<AppProvider>().setTabIndex(1);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Billing History Card
            _BillingActionCard(
              title: 'Billing History',
              description: 'View, edit, print or share past invoices and receipts.',
              subtitle: 'Total Records: $_billCount',
              icon: Icons.history_rounded,
              color: const Color(0xFF8B5CF6), // Purple for history
              onTap: () => Navigator.pushNamed(context, '/billing/history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingActionCard extends StatelessWidget {
  final String title;
  final String description;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BillingActionCard({
    required this.title,
    required this.description,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subtitle!,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.dividerColorLight, size: 20),
          ],
        ),
      ),
    );
  }
}
