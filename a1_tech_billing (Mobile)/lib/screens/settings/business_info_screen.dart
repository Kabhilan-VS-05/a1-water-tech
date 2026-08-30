import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _businessNameCtrl = TextEditingController(text: 'A1 water');
  final TextEditingController _contactNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _address1Ctrl = TextEditingController();
  final TextEditingController _address2Ctrl = TextEditingController();
  final TextEditingController _address3Ctrl = TextEditingController();
  final TextEditingController _otherInfoCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController(text: 'Water Purification & Services');

  // Tax Details
  final TextEditingController _taxLabelCtrl = TextEditingController(text: 'GSTIN');
  final TextEditingController _taxNumberCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController(text: 'Tamil Nadu');

  // Bank Details
  final TextEditingController _bankAccountNameCtrl = TextEditingController();
  final TextEditingController _bankAccountNumberCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _bankIfscCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();

  String? _logoPath;
  String? _signaturePath;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _address3Ctrl.dispose();
    _otherInfoCtrl.dispose();
    _categoryCtrl.dispose();
    _taxLabelCtrl.dispose();
    _taxNumberCtrl.dispose();
    _stateCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _bankAccountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankIfscCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessInfo() async {
    setState(() => _isLoading = true);

    final fields = [
      'companyName', 'contactName', 'supportEmail', 'supportPhone',
      'address', 'addressLine2', 'addressLine3', 'otherInfo', 'businessCategory',
      'taxLabel', 'gstin', 'businessState',
      'bankAccountName', 'bankAccountNumber', 'bankName', 'bankIfsc', 'upiId',
      'logoPath', 'signaturePath',
    ];

    for (final field in fields) {
      final val = await _db.getSetting(field);
      if (val != null && val.isNotEmpty) {
        switch (field) {
          case 'companyName': _businessNameCtrl.text = val; break;
          case 'contactName': _contactNameCtrl.text = val; break;
          case 'supportEmail': _emailCtrl.text = val; break;
          case 'supportPhone': _phoneCtrl.text = val; break;
          case 'address': _address1Ctrl.text = val; break;
          case 'addressLine2': _address2Ctrl.text = val; break;
          case 'addressLine3': _address3Ctrl.text = val; break;
          case 'otherInfo': _otherInfoCtrl.text = val; break;
          case 'businessCategory': _categoryCtrl.text = val; break;
          case 'taxLabel': _taxLabelCtrl.text = val; break;
          case 'gstin': _taxNumberCtrl.text = val; break;
          case 'businessState': _stateCtrl.text = val; break;
          case 'bankAccountName': _bankAccountNameCtrl.text = val; break;
          case 'bankAccountNumber': _bankAccountNumberCtrl.text = val; break;
          case 'bankName': _bankNameCtrl.text = val; break;
          case 'bankIfsc': _bankIfscCtrl.text = val; break;
          case 'upiId': _upiIdCtrl.text = val; break;
          case 'logoPath': _logoPath = val; break;
          case 'signaturePath': _signaturePath = val; break;
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
      if (file != null) {
        setState(() {
          if (isLogo) {
            _logoPath = file.path;
          } else {
            _signaturePath = file.path;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _saveBusinessInfo() async {
    setState(() => _isSaving = true);

    try {
      await _db.setSetting('companyName', _businessNameCtrl.text.trim());
      await _db.setSetting('contactName', _contactNameCtrl.text.trim());
      await _db.setSetting('supportEmail', _emailCtrl.text.trim());
      await _db.setSetting('supportPhone', _phoneCtrl.text.trim());
      await _db.setSetting('address', _address1Ctrl.text.trim());
      await _db.setSetting('addressLine2', _address2Ctrl.text.trim());
      await _db.setSetting('addressLine3', _address3Ctrl.text.trim());
      await _db.setSetting('otherInfo', _otherInfoCtrl.text.trim());
      await _db.setSetting('businessCategory', _categoryCtrl.text.trim());
      await _db.setSetting('taxLabel', _taxLabelCtrl.text.trim());
      await _db.setSetting('gstin', _taxNumberCtrl.text.trim());
      await _db.setSetting('businessState', _stateCtrl.text.trim());
      await _db.setSetting('bankAccountName', _bankAccountNameCtrl.text.trim());
      await _db.setSetting('bankAccountNumber', _bankAccountNumberCtrl.text.trim());
      await _db.setSetting('bankName', _bankNameCtrl.text.trim());
      await _db.setSetting('bankIfsc', _bankIfscCtrl.text.trim());
      await _db.setSetting('upiId', _upiIdCtrl.text.trim());
      if (_logoPath != null) await _db.setSetting('logoPath', _logoPath!);
      if (_signaturePath != null) await _db.setSetting('signaturePath', _signaturePath!);

      // Sync settings if online
      SyncService().uploadSettings();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business Info updated successfully!'),
          backgroundColor: Colors.black87,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          'Update Business Info',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Logo & Signature Pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageButton(
                  title: 'ADD\nLOGO',
                  imagePath: _logoPath,
                  onTap: () => _pickImage(true),
                ),
                _buildImageButton(
                  title: 'ADD\nSIGNATURE',
                  imagePath: _signaturePath,
                  onTap: () => _pickImage(false),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // General Fields
            _buildInputField('Business Name', _businessNameCtrl, hint: 'e.g. A1 water'),
            _buildInputField('Contact Name', _contactNameCtrl, hint: 'e.g. John Doe'),
            _buildInputField('Email', _emailCtrl, hint: 'e.g. info@a1water.in', keyboardType: TextInputType.emailAddress),
            _buildInputField('Phone Number', _phoneCtrl, hint: 'e.g. +91 87783 08119', keyboardType: TextInputType.phone),
            _buildInputField('Address Line 1', _address1Ctrl, hint: 'Street address / Door No'),
            _buildInputField('Address Line 2', _address2Ctrl, hint: 'Area / Landmark'),
            _buildInputField('Address Line 3', _address3Ctrl, hint: 'City, Pincode'),
            _buildInputField('Other Info', _otherInfoCtrl, hint: 'Additional business details'),
            _buildInputField('Business Category', _categoryCtrl, hint: 'e.g. Water Treatment & Purification'),

            const SizedBox(height: 24),
            _buildSectionHeader('Tax Details'),
            _buildInputField('GSTIN/PAN/VAT/Business Label', _taxLabelCtrl, hint: 'GSTIN'),
            _buildInputField('GSTIN/PAN/VAT/Business Number', _taxNumberCtrl, hint: 'e.g. 33AAAAA0000A1Z5'),
            _buildInputField('State', _stateCtrl, hint: 'e.g. Tamil Nadu'),

            const SizedBox(height: 24),
            _buildSectionHeader('Payment Instructions - Bank Details'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Bank Info\nAccount Name : ${_bankAccountNameCtrl.text.isEmpty ? '######' : _bankAccountNameCtrl.text}\nAccount Number : ${_bankAccountNumberCtrl.text.isEmpty ? '#######' : _bankAccountNumberCtrl.text}\nBank Name : ${_bankNameCtrl.text.isEmpty ? '######' : _bankNameCtrl.text}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
            ),
            _buildInputField('Account Name', _bankAccountNameCtrl, hint: 'Account holder name'),
            _buildInputField('Account Number', _bankAccountNumberCtrl, hint: 'Bank account number', keyboardType: TextInputType.number),
            _buildInputField('Bank Name', _bankNameCtrl, hint: 'e.g. HDFC Bank'),
            _buildInputField('IFSC Code', _bankIfscCtrl, hint: 'e.g. HDFC0001234'),
            _buildInputField('UPI ID', _upiIdCtrl, hint: 'e.g. a1water@upi'),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 20),
              child: Text(
                'This UPI ID will be used to generate Dynamic QR codes on the Quotations and Invoices.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBusinessInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton({required String title, String? imagePath, required VoidCallback onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(16),
              image: imagePath != null ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover) : null,
            ),
            child: imagePath == null
                ? Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                : null,
            ),
          ),
        ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
              child: Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.5)),
        ),
      ),
    );
  }
}
