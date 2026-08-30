import 'package:flutter/material.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import 'dart:io';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  Future<void> _handleExport(BuildContext context, String type) async {
    final exportService = ExportService();
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      if (type == 'bills_csv') {
        await exportService.exportBillsToCsv();
      } else if (type == 'bills_json') {
        await exportService.exportBillsToJson();
      } else if (type == 'quotations_csv') {
        await exportService.exportQuotationsToCsv();
      } else if (type == 'customers_csv') {
        await exportService.exportCustomersToCsv();
      } else if (type == 'full_backup') {
        await exportService.exportFullDatabaseBackupJson();
      }
      
      if (context.mounted) Navigator.pop(context); // hide loading
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data Backup & Export',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Backup & Export (Excel / JSON)'),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
              title: const Text('Export Bills to Excel / CSV'),
              subtitle: const Text('Download all invoices in spreadsheet format'),
              trailing: const Icon(Icons.file_download_outlined, size: 22),
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleExport(context, 'bills_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object_rounded, color: Colors.blue),
              title: const Text('Export Bills to JSON'),
              subtitle: const Text('Download raw billing data backup'),
              trailing: const Icon(Icons.file_download_outlined, size: 22),
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleExport(context, 'bills_json'),
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_rounded, color: Colors.orange),
              title: const Text('Export Quotations to Excel / CSV'),
              subtitle: const Text('Download all quotations and estimates'),
              trailing: const Icon(Icons.file_download_outlined, size: 22),
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleExport(context, 'quotations_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: Colors.teal),
              title: const Text('Export Customers to Excel / CSV'),
              subtitle: const Text('Download client address book and contacts'),
              trailing: const Icon(Icons.file_download_outlined, size: 22),
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleExport(context, 'customers_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_rounded, color: AppTheme.primaryColor),
              title: const Text('Full Offline Database Backup (JSON)'),
              subtitle: const Text('Complete backup of bills, quotes, orders, catalog'),
              trailing: const Icon(Icons.file_download_outlined, size: 22),
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleExport(context, 'full_backup'),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Cloud Storage (Supabase 500 MB)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage_rounded, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Supabase Free Tier: 500 MB',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Capacity: ~400,000 to 500,000 total records.\n'
                    '• Estimated duration: Over 20+ years of billing data at 50 bills/day.\n'
                    '• Images are stored in AWS S3 and take 0 MB of database storage.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
