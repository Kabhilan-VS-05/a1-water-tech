import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../models/sync_result.dart';
import '../../services/pdf_service.dart';
import 'dialogs.dart';

class BillViewScreen extends StatefulWidget {
  final String? billId;
  final Bill? bill;
  final bool isEditable;

  const BillViewScreen({
    super.key,
    this.billId,
    this.bill,
    this.isEditable = true,
  });

  @override
  State<BillViewScreen> createState() => _BillViewScreenState();
}

class _BillViewScreenState extends State<BillViewScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  Bill? _bill;
  Customer? _customer;
  bool _isLoading = true;
  bool _isEditing = false;

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerGstController = TextEditingController();
  final _gstOverrideController = TextEditingController();

  String _selectedPaymentMode = 'pending';
  String _selectedStatus = 'draft';
  List<BillItem> _editableItems = [];
  double _subtotal = 0;
  double _gstAmount = 0;
  double _total = 0;
  DateTime _billDate = DateTime.now();
  
  bool _overrideGst = false;
  String _overrideGstType = 'percentage';

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    Bill? bill = widget.bill;
    if (bill == null && widget.billId != null) {
      final bills = await _db.getBills();
      bill = bills.firstWhere((b) => b.id == widget.billId);
    }
    if (bill == null) return;
    final currentBill = bill;

    Customer? customer;
    if (currentBill.customerId != null) {
      customer = await _db.getCustomerById(currentBill.customerId!);
    }

    setState(() {
      _bill = currentBill;
      _customer = customer;
      _isLoading = false;

      // Initialize controllers
      _customerNameController.text = currentBill.customerName;
      _customerPhoneController.text = currentBill.customerPhone ?? '';
      _customerAddressController.text = currentBill.customerAddress ?? '';
      _customerGstController.text = currentBill.customerGst ?? '';
      _selectedPaymentMode = currentBill.paymentMode;
      _selectedStatus = currentBill.status;
      _editableItems = List.from(currentBill.items);
      _billDate = currentBill.createdAt;
      
      double itemGstSum = _editableItems.fold(0.0, (sum, item) => sum + item.gstAmount);
      if ((currentBill.gstAmount - itemGstSum).abs() > 0.1) {
        _overrideGst = true;
        _overrideGstType = 'rupees';
        _gstOverrideController.text = currentBill.gstAmount.toStringAsFixed(2);
      }
      
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double sub = 0;
    double itemGstSum = 0;
    for (var item in _editableItems) {
      sub += item.price * item.quantity;
      itemGstSum += item.gstAmount;
    }
    setState(() {
      _subtotal = sub;
      
      if (_overrideGst && _gstOverrideController.text.isNotEmpty) {
        final val = double.tryParse(_gstOverrideController.text) ?? 0.0;
        if (_overrideGstType == 'percentage') {
          _gstAmount = (sub * val) / 100;
        } else {
          _gstAmount = val;
        }
      } else {
        _gstAmount = itemGstSum;
      }
      
      _total = sub + _gstAmount;
    });
  }

  void _updateItemQuantity(int index, int delta) {
    setState(() {
      final item = _editableItems[index];
      final newQty = item.quantity + delta;
      if (newQty > 0) {
        final itemTotal = item.price * newQty;
        final itemGst = itemTotal * (item.gstPercent / 100);
        _editableItems[index] = item.copyWith(
          quantity: newQty,
          gstAmount: itemGst,
          total: itemTotal + itemGst,
        );
        _calculateTotals();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
      _calculateTotals();
    });
  }

  Future<void> _addItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const AddItemDialog(),
    );

    if (result != null) {
      final CatalogItem catalogItem = result['item'];
      final int quantity = result['quantity'];

      final itemTotal = catalogItem.price * quantity;
      final itemGst = itemTotal * (catalogItem.gstPercent / 100);

      setState(() {
        _editableItems.add(
          BillItem(
            itemId: catalogItem.id,
            name: catalogItem.name,
            type: catalogItem.type,
            price: catalogItem.price,
            quantity: quantity,
            gstPercent: catalogItem.gstPercent,
            gstAmount: itemGst,
            total: itemTotal + itemGst,
            imageUrl: catalogItem.imageUrl,
          ),
        );
        _calculateTotals();
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_billDate),
      );
      if (time != null) {
        setState(() {
          _billDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<bool?> _showSignatureDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signature Option'),
        content: const Text('Choose how you want to sign the invoice:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Manual
            child: const Text('MANUAL SIGN'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Digital
            child: const Text('DIGITAL SIGN'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (_bill == null) return;

    final isDigital = await _showSignatureDialog();
    if (isDigital == null) return; // User cancelled

    setState(() => _isLoading = true);

    try {
      final pdfFile = await PdfService.generateInvoice(
        _bill!,
        customer: _customer,
        isDigitalSignature: isDigital,
      );

      // Show PDF
      await Printing.layoutPdf(
        name: 'Invoice_${_bill!.billNumber}',
        onLayout: (format) => pdfFile,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (_bill == null || !widget.isEditable) return;

    final updatedBill = _bill!.copyWith(
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
      customerAddress: _customerAddressController.text.isEmpty ? null : _customerAddressController.text,
      customerGst: _customerGstController.text.isEmpty ? null : _customerGstController.text,
      items: _editableItems,
      subtotal: _subtotal,
      gstAmount: _gstAmount,
      total: _total,
      status: _selectedStatus,
      paymentMode: _selectedPaymentMode,
      updatedAt: DateTime.now(),
      createdAt: _billDate,
    );

    await _db.updateBill(updatedBill);

    // Update customer if exists
    if (_customer != null) {
      final updatedCustomer = _customer!.copyWith(
        name: _customerNameController.text,
        phone: _customerPhoneController.text.isEmpty
            ? null
            : _customerPhoneController.text,
        address: _customerAddressController.text.isEmpty
            ? null
            : _customerAddressController.text,
      );
      await _db.updateCustomer(updatedCustomer);
    }

    await _loadBill();

    // Auto-sync to AWS if online
    final syncResult = await _sync.syncOnSave();

    setState(() => _isEditing = false);

    if (mounted) {
      String message = 'Bill updated successfully';

      switch (syncResult) {
        case SyncResult.success:
          message += ' & synced to AWS';
          break;
        case SyncResult.offline:
          message += ' (offline - will sync later)';
          break;
        case SyncResult.alreadySyncing:
          message += ' (sync in progress)';
          break;
        case SyncResult.failed:
          message += ' (sync failed)';
          break;
        default:
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteBill() async {
    if (_bill == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete bill #${_bill!.billNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteBill(_bill!.id);

      // Auto-sync to AWS if online
      await _sync.syncOnSave();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #${_bill!.billNumber} deleted & synced to AWS'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_bill == null) {
      return const Scaffold(body: Center(child: Text('Bill not found')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4F46E5);
    final surfaceColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill #${_bill!.billNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isEditing)
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(_billDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_calendar, size: 16, color: Colors.white),
                    ]
                  ),
                ),
              )
            else
              Text(DateFormat('dd MMM yyyy, hh:mm a').format(_bill!.createdAt), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isEditable && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Bill',
            ),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: _saveChanges, tooltip: 'Save Changes'),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () => setState(() => _isEditing = false),
              tooltip: 'Cancel',
            ),
          if (widget.isEditable)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBill,
              color: Colors.redAccent,
              tooltip: 'Delete Bill',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Payment Summary Card
                  _buildSectionCard(
                    child: Column(
                      children: [
                        if (_isEditing) ...[
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: ['draft', 'pending', 'confirmed', 'paid', 'cancelled'].map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _getStatusColorForString(status))),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedStatus = v);
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _selectedPaymentMode,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Payment Mode',
                                  fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: ['pending', 'cash', 'upi', 'card', 'bank_transfer'].map((mode) {
                                  return DropdownMenuItem(
                                    value: mode,
                                    child: Text(mode.replaceAll('_', ' ').toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedPaymentMode = v);
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBadge(
                                _bill!.status.toUpperCase(),
                                _getBillStatusColor(),
                              ),
                              _buildBadge(
                                _bill!.paymentMode.toUpperCase(),
                                primaryColor,
                                isOutline: true,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Items', '${_isEditing ? _editableItems.length : _bill!.items.length}'),
                            _buildStatItem('Subtotal', '₹${(_isEditing ? _subtotal : _bill!.subtotal).toStringAsFixed(0)}'),
                            _buildStatItem('Tax', '₹${(_isEditing ? _gstAmount : _bill!.gstAmount).toStringAsFixed(0)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Details Section
                  _buildSectionHeader('Customer Details', Icons.person_outline),
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isEditing
                            ? _buildTextField(_customerNameController, label: 'Full Name')
                            : _buildInfoDetail('Name', _bill!.customerName, Icons.person),
                        const SizedBox(height: 12),
                        _isEditing
                            ? _buildTextField(_customerPhoneController, label: 'Phone Number', keyboardType: TextInputType.phone)
                            : _buildInfoDetail('Phone', _bill!.customerPhone ?? 'Not Provided', Icons.phone),
                        const SizedBox(height: 12),
                        _isEditing
                            ? _buildTextField(_customerAddressController, label: 'Address', maxLines: 3)
                            : _buildInfoDetail('Address', _bill!.customerAddress ?? 'Not Provided', Icons.location_on),
                        const SizedBox(height: 12),
                        _isEditing
                            ? _buildTextField(_customerGstController, label: 'Customer GSTIN (Optional)')
                            : (_bill!.customerGst != null && _bill!.customerGst!.isNotEmpty
                                ? _buildInfoDetail('GSTIN', _bill!.customerGst!, Icons.receipt_long)
                                : const SizedBox.shrink()),
                        if (_customer != null && !_isEditing) ...[
                          const Divider(height: 32),
                          Row(
                            children: [
                              Icon(Icons.history, size: 16, color: AppTheme.slate.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Previous Visits: ${_customer!.totalVisits} | Total Spent: ₹${_customer!.totalSpent.toStringAsFixed(0)}',
                                style: TextStyle(color: AppTheme.slate.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isEditing) ...[
                    _buildSectionHeader('Tax Settings', Icons.percent),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slate.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calculate_outlined, size: 20, color: _overrideGst ? AppTheme.primaryColor : Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Custom GST Override', 
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      color: _overrideGst ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.grey
                                    )
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 24,
                                child: Switch(
                                  value: _overrideGst,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _overrideGst = val;
                                      _calculateTotals();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_overrideGst) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _overrideGstType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: AppTheme.slate.shade200),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'percentage', child: Text('Percent (%)', style: TextStyle(fontSize: 13))),
                                      DropdownMenuItem(value: 'rupees', child: Text('Rupees (₹)', style: TextStyle(fontSize: 13))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _overrideGstType = val;
                                          _calculateTotals();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _gstOverrideController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: _overrideGstType == 'percentage' ? 'e.g. 18' : 'e.g. 500',
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: AppTheme.slate.shade200),
                                      ),
                                    ),
                                    onChanged: (_) {
                                      _calculateTotals();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Items List Section
                  _buildSectionHeader('Bill Items', Icons.receipt_long_outlined),
                  ...(_isEditing ? _editableItems : _bill!.items).asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildItemTile(item, index);
                  }),
                  
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Item to Bill'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Space for fab
                ],
              ),
            ),
          ),
          
          // Bottom Summary Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: AppTheme.slate, fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(
                        '₹${(_isEditing ? _total : _bill!.total).toStringAsFixed(0)}',
                        style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text('GENERATE PDF', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.slate.shade600),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppTheme.slate.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildBadge(String text, Color color, {bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: isOutline ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.slate.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoDetail(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate.withOpacity(0.2) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: isDark ? Colors.blue.shade300 : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.slate.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(BillItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFEEF2FF).withOpacity(0.1) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(color: isDark ? Colors.blue.shade300 : const Color(0xFF4F46E5), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x ₹${item.price.toStringAsFixed(0)}',
                  style: TextStyle(color: AppTheme.slate.shade400, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Row(
              children: [
                _buildQtyBtn(Icons.remove, () => _updateItemQuantity(index, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _buildQtyBtn(Icons.add, () => _updateItemQuantity(index, 1)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeItem(index),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4F46E5))),
                Text('GST ${item.gstPercent.toStringAsFixed(0)}%', style: TextStyle(color: AppTheme.slate.shade400, fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate.shade800 : AppTheme.slate.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppTheme.slate.shade700 : AppTheme.slate.shade200),
        ),
        child: Icon(icon, size: 16, color: isDark ? Colors.white70 : AppTheme.slate.shade700),
      ),
    );
  }

  Color _getStatusColorForString(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.orange;
      case 'pending': return Colors.amber.shade700;
      case 'confirmed': return Colors.blue;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildTextField(TextEditingController controller, {required String label, int maxLines = 1, TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppTheme.slate.shade400 : AppTheme.slate.shade500, fontSize: 13),
        filled: true,
        fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppTheme.slate.withOpacity(0.2) : AppTheme.slate.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.blue.shade400 : const Color(0xFF4F46E5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Color _getBillStatusColor() {
    if (_bill == null) return Colors.grey;
    switch (_bill!.status.toLowerCase()) {
      case 'draft': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
