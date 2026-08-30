import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../services/export_service.dart';
import '../../models/sync_result.dart';
import 'backup_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  
  final Map<String, String> _settings = {
    'companyName': 'A1 Water Tech',
    'supportPhone': '+91 98765 43210',
    'supportEmail': 'support@a1water.in',
    'address': '123 Water Street, Industrial Area',
    'addressLine2': '',
    'addressLine3': '',
    'locality': '',
    'gstin': '',
    'defaultGstRate': '18',
    'invoicePrefix': 'BILL',
    'gstEnabled': 'true',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    // First, try to fetch fresh settings from AWS if online
    final sync = SyncService();
    if (sync.isOnline) {
      await sync.syncSettings();
    }
    
    for (String key in _settings.keys) {
      final val = await _db.getSetting(key);
      if (val != null) {
        _settings[key] = val;
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final provider = context.read<AppProvider>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('How should the app look?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.brightness_5_rounded),
                title: const Text('Always Light'),
                onTap: () {
                  provider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_2_rounded),
                title: const Text('Always Dark'),
                onTap: () {
                  provider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: const Text('Follow Phone Settings'),
                onTap: () {
                  provider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateSetting(String key, String value) async {
    await _db.setSetting(key, value);
    setState(() {
      _settings[key] = value;
    });
    
    // Automatically push to AWS if online
    final sync = SyncService();
    if (sync.isOnline) {
      sync.uploadSettings().then((result) {
        if (mounted && result.message.contains('Success')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings synced to website!')),
          );
        }
      });
    }
  }

  Future<void> _showEditDialog(String key, String title, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter new $title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateSetting(key, controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Company Details'),
              _buildSettingTile(Icons.business_rounded, 'companyName', 'Company Name'),
              _buildSettingTile(Icons.phone_rounded, 'supportPhone', 'Support Phone'),
              _buildSettingTile(Icons.email_rounded, 'supportEmail', 'Support Email'),
              _buildSettingTile(Icons.location_on_rounded, 'address', 'Address Line 1'),
              _buildSettingTile(Icons.add_location_alt_rounded, 'addressLine2', 'Address Line 2'),
              _buildSettingTile(Icons.map_rounded, 'addressLine3', 'Address Line 3'),
              _buildSettingTile(Icons.my_location_rounded, 'locality', 'Locality'),
              _buildSettingTile(Icons.badge_rounded, 'gstin', 'GSTIN'),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Bill Settings'),
              _buildSettingTile(Icons.percent_rounded, 'defaultGstRate', 'Default GST Rate (%)'),
              _buildSettingTile(Icons.receipt_rounded, 'invoicePrefix', 'Invoice Prefix'),
              SwitchListTile(
                title: const Text('Show GST in Bills'),
                value: _settings['gstEnabled'] == 'true',
                activeColor: AppTheme.accentColor,
                onChanged: (v) {
                  _updateSetting('gstEnabled', v.toString());
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Data Management'),
              ListTile(
                leading: const Icon(Icons.backup_rounded, color: AppTheme.primaryColor),
                title: const Text('Data Backup & Export'),
                subtitle: const Text('Export to Excel/JSON and Cloud Storage info'),
                trailing: const Icon(Icons.chevron_right_rounded),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
                  );
                },
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('App Settings'),
              ListTile(
                leading: const Icon(Icons.palette_rounded, color: AppTheme.accentColor),
                title: const Text('App Look'),
                subtitle: Text(context.watch<AppProvider>().themeMode.toString().split('.').last.toUpperCase()),
                onTap: _showThemeSelector,
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppTheme.accentColor),
                title: const Text('App Version'),
                subtitle: const Text('2.0.0 (Production)'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 40),
            ],
          ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String key, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(title),
      subtitle: Text(_settings[key] ?? ''),
      trailing: const Icon(Icons.edit_rounded, size: 20),
      contentPadding: EdgeInsets.zero,
      onTap: () => _showEditDialog(key, title, _settings[key] ?? ''),
    );
  }
}
