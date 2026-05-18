import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../models/sync_result.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  Map<String, dynamic> _stats = {
    'todayRevenue': 0.0,
    'todayBills': 0,
    'pendingOrders': 0,
    'pendingBills': 0,
  };
  List<Bill> _recentBills = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load local stats first (fast)
    final localStats = await _db.getDashboardStats();
    final recentBills = await _db.getBills(limit: 5);
    
    if (mounted) {
      setState(() {
        _stats = localStats;
        _recentBills = recentBills;
        _isLoading = false;
      });
    }

    // Then try to fetch fresh remote metrics if online
    _fetchRemoteStats();
  }

  Future<void> _fetchRemoteStats() async {
    if (!_sync.isOnline) return;

    final remoteMetrics = await _sync.getRemoteMetrics(days: 1);
    final localStats = await _db.getDashboardStats();
    
    if (mounted) {
      setState(() {
        if (remoteMetrics != null) {
          _stats = {
            ...localStats,
            'todayRevenue': (remoteMetrics['revenueInRange'] ?? remoteMetrics['totalRevenue'] ?? 0.0).toDouble(),
            'todayBills': remoteMetrics['salesCountInRange'] ?? remoteMetrics['salesCount'] ?? 0,
            'pendingOrders': remoteMetrics['pendingOrders'] ?? localStats['pendingOrders'] ?? 0,
            'pendingBills': remoteMetrics['billsInRange'] ?? remoteMetrics['billsCount'] ?? 0,
            'totalBills': remoteMetrics['totalBills'] ?? localStats['totalBills'] ?? 0,
          };
        } else {
          _stats = localStats;
        }
      });
    }
  }

  Future<void> _backgroundSync() async {
    try {
      await _sync.syncAll();
      await _fetchRemoteStats();
      final freshRecentBills = await _db.getBills(limit: 5);
      if (mounted) {
        setState(() {
          _recentBills = freshRecentBills;
        });
      }
    } catch (e) {
      print('Background sync error: $e');
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    final result = await _sync.manualSync();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result == SyncResult.success ? AppTheme.secondaryColor : AppTheme.errorColor,
        ),
      );
      if (result == SyncResult.success || result == SyncResult.partial) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _manualSync,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    Text('What to do?', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last Bills', style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () => context.read<AppProvider>().setTabIndex(2), // Navigate to Billing
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentBills(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _sync.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 16,
                  color: _sync.isOnline ? AppTheme.secondaryColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _sync.isOnline ? 'System Online' : 'Offline Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _sync.isOnline ? AppTheme.secondaryColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondaryLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _PremiumStatCard(
          title: 'Money Today',
          value: '₹${_stats['todayRevenue'].toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          onTap: () => context.read<AppProvider>().setTabIndex(2), // Billing
        ),
        _PremiumStatCard(
          title: 'New Orders',
          value: '${_stats['pendingOrders']}',
          icon: Icons.local_shipping_rounded,
          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
          onTap: () => context.read<AppProvider>().setTabIndex(1, ordersTabIndex: 0),
        ),
        _PremiumStatCard(
          title: 'Service Visits',
          value: '${_stats['pendingBookings'] ?? 0}',
          icon: Icons.handyman_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          onTap: () => context.read<AppProvider>().setTabIndex(1, ordersTabIndex: 0),
        ),
        _PremiumStatCard(
          title: 'All Bills',
          value: '${_stats['totalBills'] ?? 0}',
          icon: Icons.receipt_long_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
          onTap: () {
            context.read<AppProvider>().setTabIndex(2);
            Navigator.pushNamed(context, '/billing/history');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'New Bill', 
            icon: Icons.add_circle_outline_rounded, 
            color: AppTheme.accentColor, 
            onTap: () => Navigator.pushNamed(context, '/billing/manual'),
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            title: 'Add Product', 
            icon: Icons.inventory_2_outlined, 
            color: AppTheme.secondaryColor, 
            onTap: () => Navigator.pushNamed(context, '/catalog', arguments: {'tab': 0}),
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            title: 'Add Service', 
            icon: Icons.handyman_outlined, 
            color: const Color(0xFF8B5CF6), 
            onTap: () => Navigator.pushNamed(context, '/catalog', arguments: {'tab': 1}),
          )
        ),
      ],
    );
  }

  Widget _buildRecentBills() {
    if (_recentBills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.textSecondaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No recent bills found', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentBills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final bill = _recentBills[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.customerName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('#${bill.billNumber}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${bill.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bill.status == 'paid' ? AppTheme.secondaryColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bill.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: bill.status == 'paid' ? AppTheme.secondaryColor : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PremiumStatCard({required this.title, required this.value, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    ),
  );
}
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
