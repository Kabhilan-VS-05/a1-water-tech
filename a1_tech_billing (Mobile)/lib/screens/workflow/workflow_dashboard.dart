import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/logger_service.dart';
import '../../theme/app_theme.dart';
import '../quotation/quotation_screen.dart';
import '../purchase_order/purchase_order_screen.dart';

class WorkflowDashboard extends StatefulWidget {
  const WorkflowDashboard({super.key});

  @override
  State<WorkflowDashboard> createState() => _WorkflowDashboardState();
}

class _WorkflowDashboardState extends State<WorkflowDashboard> {
  final DatabaseService _db = DatabaseService();
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final quotations = await _db.getQuotations();
      final pos = await _db.getPurchaseOrders();
      final bills = await _db.getBills();

      return {
        'totalQuotations': quotations.length,
        'acceptedQuotations': quotations.where((q) => q.status == 'accepted').length,
        'totalPOs': pos.length,
        'acceptedPOs': pos.where((p) => p.status == 'accepted').length,
        'totalBills': bills.length,
        'quotations': quotations,
        'pos': pos,
        'bills': bills,
      };
    } catch (e) {
      AppLogger.error('Failed to load dashboard data: $e', tag: 'Workflow');
      return {
        'totalQuotations': 0,
        'acceptedQuotations': 0,
        'totalPOs': 0,
        'acceptedPOs': 0,
        'totalBills': 0,
        'quotations': <Quotation>[],
        'pos': <PurchaseOrder>[],
        'bills': <Bill>[],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Workflow', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDocumentFlow(),
                const SizedBox(height: 24),
                _buildStatsSection(data),
                const SizedBox(height: 24),
                _buildQuickActionsSection(),
                const SizedBox(height: 24),
                _buildRecentDocumentsSection(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Document Workflow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildFlowStep('Quotation', '1', Colors.blue),
              _buildFlowArrow(),
              _buildFlowStep('Purchase Order', '2', Colors.orange),
              _buildFlowArrow(),
              _buildFlowStep('Invoice', '3', Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create quotations, convert to POs, and finalize as invoices',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildFlowStep(String title, String number, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 16,
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.arrow_downward, color: AppTheme.accentColor, size: 24),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Quotations',
                '${data['totalQuotations']}',
                'Accepted: ${data['acceptedQuotations']}',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Purchase Orders',
                '${data['totalPOs']}',
                'Accepted: ${data['acceptedPOs']}',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Invoices',
                '${data['totalBills']}',
                'Total',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'New Quotation',
                Icons.description,
                Colors.blue,
                () => _navigateToQuotation(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'New PO',
                Icons.receipt,
                Colors.orange,
                () => _navigateToPO(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRecentDocumentsSection(Map<String, dynamic> data) {
    final quotations = (data['quotations'] as List?)?.whereType<Quotation>().toList() ?? [];
    final pos = (data['pos'] as List?)?.whereType<PurchaseOrder>().toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (quotations.isEmpty && pos.isEmpty)
          const Center(
            child: Text('No documents yet', style: TextStyle(color: AppTheme.textSecondaryLight)),
          )
        else ...[
          if (quotations.isNotEmpty) ...[
            const Text('Latest Quotations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...quotations.take(3).map((q) => _buildDocumentTile(
              q.quotationNumber,
              q.customerName,
              '₹${q.total.toStringAsFixed(0)}',
              _getStatusColor(q.status),
            )),
            const SizedBox(height: 16),
          ],
          if (pos.isNotEmpty) ...[
            const Text('Latest Purchase Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...pos.take(3).map((p) => _buildDocumentTile(
              p.poNumber,
              p.customerName,
              '₹${p.total.toStringAsFixed(0)}',
              _getStatusColor(p.status),
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildDocumentTile(String title, String subtitle, String amount, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.description, color: Colors.white, size: 18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToQuotation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuotationScreen()),
    );
  }

  void _navigateToPO() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PurchaseOrderScreen()),
    );
  }
}
