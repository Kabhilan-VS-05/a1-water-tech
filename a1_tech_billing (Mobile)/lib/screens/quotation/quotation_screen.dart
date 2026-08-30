import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/invoice_number_generator.dart';
import '../billing/manual_billing_screen.dart';
import '../terms/terms_screen.dart';

// ============================================================================
// 1. QUOTATION LIST SCREEN
// ============================================================================

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final DatabaseService _db = DatabaseService();
  List<Quotation> _quotations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final list = await _db.getQuotations();
    if (mounted) {
      setState(() {
        _quotations = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _quotations.where((q) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return q.quotationNumber.toLowerCase().contains(query) ||
          q.customerName.toLowerCase().contains(query) ||
          (q.customerPhone != null && q.customerPhone!.contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quotation List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by Name, Company OR Quotation#',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'You don\'t have any quotations',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final q = filtered[i];
                          return Card(
                            clipBehavior: Clip.hardEdge,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    q.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '₹${q.total.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${q.quotationNumber} • ${DateFormat('dd/MM/yyyy').format(q.createdAt)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        q.status.toUpperCase(),
                                        style: TextStyle(color: Colors.teal.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: q)),
                                ).then((_) => _loadQuotations());
                              },
                            ),
                            );
                          },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE91E63), // Pink / Magenta FAB matching video
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('MAKE QUOTATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          ).then((_) => _loadQuotations());
        },
      ),
    );
  }
}

// ============================================================================
// 2. MAKE QUOTATION SCREEN (CARD-BASED BLOCK LAYOUT MATCHING VIDEO)
// ============================================================================

class CreateQuotationScreen extends StatefulWidget {
  final Quotation? quotation;
  const CreateQuotationScreen({super.key, this.quotation});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();

  DateTime _quotationDate = DateTime.now();
  String _quotationNumber = '';

  Customer? _selectedCustomer;
  final List<QuotationItem> _items = [];

  // Other charge
  String _otherChargeLabel = 'Other Charges';
  double _otherChargeAmount = 0.0;
  bool _isOtherChargeTaxable = false;
  double _otherChargeGstPercent = 18.0;

  // Terms & Notes
  String _termsAndConditions = '1. Prices are valid for 15 days from quotation date.\n2. Standard delivery & installation included.\n3. Taxes charged as applicable at invoice generation.';
  String _notes = '';
  bool _isRoundedOff = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.quotation != null) {
      final q = widget.quotation!;
      _quotationNumber = q.quotationNumber;
      _quotationDate = q.createdAt;
      _selectedCustomer = Customer(
        id: q.customerId ?? 'cust-${DateTime.now().millisecondsSinceEpoch}',
        name: q.customerName,
        phone: q.customerPhone,
        address: q.customerAddress,
        email: q.customerEmail,
        createdAt: DateTime.now(),
      );
      _items.clear();
      _items.addAll(q.items);
      _otherChargeLabel = q.otherChargeLabel ?? 'Other Charges';
      _otherChargeAmount = q.otherChargeAmount ?? 0.0;
      _isOtherChargeTaxable = q.isOtherChargeTaxable;
      _otherChargeGstPercent = q.otherChargeGstPercent ?? 18.0;
      _termsAndConditions = q.terms ?? _termsAndConditions;
      _notes = q.notes ?? '';
      _isRoundedOff = q.isRoundedOff;
    } else {
      try {
        _quotationNumber = await InvoiceNumberGenerator.generateQuotationNumber();
      } catch (_) {
        _quotationNumber = 'QT-${DateFormat('yyyyMMdd').format(DateTime.now())}-001';
      }
    }
    if (mounted) setState(() {});
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + (i.price * i.quantity));
  double get _taxTotal => _items.fold(0, (sum, i) => sum + i.gstAmount);
  double get _otherChargeGst => (_isOtherChargeTaxable && _otherChargeAmount > 0)
      ? (_otherChargeAmount * _otherChargeGstPercent) / 100
      : 0.0;

  double get _grandTotal {
    final raw = _subtotal + _taxTotal + _otherChargeAmount + _otherChargeGst;
    return _isRoundedOff ? raw.roundToDouble() : raw;
  }

  // Pick Customer
  Future<void> _pickCustomer() async {
    final customers = await _db.getCustomers();
    if (!mounted) return;

    final picked = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SelectCustomerSheet(customers: customers),
    );

    if (picked != null) {
      setState(() => _selectedCustomer = picked);
    }
  }

  // Pick Product
  Future<void> _pickProduct() async {
    final catalog = [
      ...await _db.getCatalogItems(type: 'product'),
      ...await _db.getCatalogItems(type: 'service'),
    ];
    if (!mounted) return;

    final item = await showModalBottomSheet<QuotationItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SelectProductSheet(catalog: catalog),
    );

    if (item != null) {
      setState(() => _items.add(item));
    }
  }

  // Other Charges Modal
  Future<void> _showOtherChargesModal() async {
    final labelCtrl = TextEditingController(text: _otherChargeLabel);
    final amountCtrl = TextEditingController(text: _otherChargeAmount > 0 ? _otherChargeAmount.toString() : '');
    final gstCtrl = TextEditingController(text: _otherChargeGstPercent.toString());
    bool isTaxable = _isOtherChargeTaxable;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Other Charge Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Other Charge Label',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Other Charge Amount',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is Taxable?', style: TextStyle(fontSize: 14)),
                value: isTaxable,
                onChanged: (v) => setSheetState(() => isTaxable = v ?? false),
              ),
              if (isTaxable) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: gstCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'GST (IN %)',
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _otherChargeLabel = labelCtrl.text.trim().isEmpty ? 'Other Charges' : labelCtrl.text.trim();
                      _otherChargeAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      _isOtherChargeTaxable = isTaxable;
                      _otherChargeGstPercent = double.tryParse(gstCtrl.text.trim()) ?? 18.0;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Terms Modal
  Future<void> _pickTerms() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const TermsConditionsScreen(
          isSelectionMode: true,
          documentType: 'Quotation',
        ),
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _termsAndConditions = picked);
    }
  }

  Future<void> _generateQuotation() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final quotation = Quotation(
        id: widget.quotation?.id ?? _quotationNumber,
        quotationNumber: _quotationNumber,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer?.phone,
        customerAddress: _selectedCustomer?.address,
        customerEmail: _selectedCustomer?.email,
        items: _items,
        subtotal: _subtotal,
        gstAmount: _taxTotal,
        total: _grandTotal,
        status: 'sent',
        validUntil: DateTime.now().add(const Duration(days: 15)),
        notes: _notes.isNotEmpty ? _notes : null,
        otherChargeLabel: _otherChargeAmount > 0 ? _otherChargeLabel : null,
        otherChargeAmount: _otherChargeAmount > 0 ? _otherChargeAmount : null,
        isOtherChargeTaxable: _isOtherChargeTaxable,
        otherChargeGstPercent: _isOtherChargeTaxable ? _otherChargeGstPercent : null,
        terms: _termsAndConditions.isNotEmpty ? _termsAndConditions : null,
        isRoundedOff: _isRoundedOff,
        createdAt: _quotationDate,
        updatedAt: DateTime.now(),
      );

      await _db.insertQuotation(quotation);
      _sync.syncOnSave();

      if (!mounted) return;

      // Navigate to Quotation Detail Screen (matching video frame 00:44)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: quotation)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Make Quotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Top Metadata Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _quotationDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _quotationDate = picked);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quotation Date', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(DateFormat('dd/MM/yyyy').format(_quotationDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Quotation No', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_quotationNumber.isEmpty ? '-' : _quotationNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Other Info:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card Rows List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // 1. TO (CUSTOMER) Card
                _buildCardSection(
                  title: 'TO (CUSTOMER)',
                  hasContent: _selectedCustomer != null,
                  content: _selectedCustomer != null
                      ? Text(
                          _selectedCustomer!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        )
                      : null,
                  onAdd: _pickCustomer,
                  onDelete: () => setState(() => _selectedCustomer = null),
                ),
                const SizedBox(height: 12),

                // 2. PRODUCTS Card
                _buildProductsSection(),
                const SizedBox(height: 12),

                // 3. OTHER CHARGE Card
                _buildCardSection(
                  title: 'OTHER CHARGE',
                  hasContent: _otherChargeAmount > 0,
                  content: _otherChargeAmount > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_otherChargeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('₹${_otherChargeAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        )
                      : null,
                  onAdd: _showOtherChargesModal,
                  onDelete: () => setState(() => _otherChargeAmount = 0.0),
                ),
                const SizedBox(height: 12),

                // 4. TERMS & CONDITIONS Card
                _buildCardSection(
                  title: 'TERMS & CONDITIONS',
                  hasContent: _termsAndConditions.isNotEmpty,
                  content: _termsAndConditions.isNotEmpty
                      ? Text(
                          _termsAndConditions,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        )
                      : null,
                  onAdd: _pickTerms,
                  onDelete: () => setState(() => _termsAndConditions = ''),
                ),
                const SizedBox(height: 12),

                // 5. ROUND OFF AMOUNT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ROUND OFF AMOUNT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      Checkbox(
                        value: _isRoundedOff,
                        activeColor: Colors.black87,
                        onChanged: (v) => setState(() => _isRoundedOff = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Amount Due', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _generateQuotation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Generate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required bool hasContent,
    Widget? content,
    required VoidCallback onAdd,
    VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Theme.of(context).cardColor, size: 16),
                  ),
                ),
              ],
            ),
          ),
          if (hasContent && content != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: content),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PRODUCTS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
                GestureDetector(
                  onTap: _pickProduct,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Theme.of(context).cardColor, size: 16),
                  ),
                ),
              ],
            ),
          ),
          if (_items.isNotEmpty) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ${item.quantity} * ₹${item.price.toStringAsFixed(0)} = ₹${(item.quantity * item.price).toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Total amount: ₹${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 3. SELECT CUSTOMER BOTTOM SHEET
// ============================================================================

class _SelectCustomerSheet extends StatefulWidget {
  final List<Customer> customers;
  const _SelectCustomerSheet({required this.customers});

  @override
  State<_SelectCustomerSheet> createState() => _SelectCustomerSheetState();
}

class _SelectCustomerSheetState extends State<_SelectCustomerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((c) {
      final q = _search.toLowerCase().trim();
      return c.name.toLowerCase().contains(q) || (c.phone != null && c.phone!.contains(q));
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by Name OR Company Name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No customers found', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        return ListTile(
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone ?? c.address ?? ''),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. SELECT PRODUCT & ADD QUOTATION PRODUCT BOTTOM SHEET
// ============================================================================

class _SelectProductSheet extends StatefulWidget {
  final List<CatalogItem> catalog;
  const _SelectProductSheet({required this.catalog});

  @override
  State<_SelectProductSheet> createState() => _SelectProductSheetState();
}

class _SelectProductSheetState extends State<_SelectProductSheet> {
  String _search = '';
  CatalogItem? _selectedItem;

  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_selectedItem != null) {
      return _buildAddQuotationProductView();
    }

    final filtered = widget.catalog.where((item) {
      final q = _search.toLowerCase().trim();
      return item.name.toLowerCase().contains(q);
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by Name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No products found', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        return ListTile(
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Price: ₹${item.price.toStringAsFixed(0)} • GST: ${item.gstPercent.toStringAsFixed(0)}%'),
                          trailing: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                              _priceCtrl.text = item.price.toStringAsFixed(0);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddQuotationProductView() {
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedItem = null),
          ),
          title: const Text('Add Quotation Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_selectedItem!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description (0/2000)',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
                    final price = double.tryParse(_priceCtrl.text.trim()) ?? _selectedItem!.price;
                    final subtotal = price * qty;
                    final gstAmount = (subtotal * _selectedItem!.gstPercent) / 100;

                    final quotationItem = QuotationItem(
                      itemId: _selectedItem!.id,
                      name: _selectedItem!.name,
                      type: _selectedItem!.type,
                      hsn: _selectedItem!.hsn,
                      price: price,
                      quantity: qty,
                      gstPercent: _selectedItem!.gstPercent,
                      gstAmount: gstAmount,
                      total: subtotal + gstAmount,
                      imageUrl: _selectedItem!.imageUrl,
                    );

                    Navigator.pop(context, quotationItem);
                  },
                  child: const Text('Add To Quotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. QUOTATION DETAIL SCREEN (LIVE PDF VIEW + 5 ACTIONS MATCHING VIDEO 00:44)
// ============================================================================

class QuotationDetailScreen extends StatefulWidget {
  final Quotation quotation;
  const QuotationDetailScreen({super.key, required this.quotation});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _duplicateQuotation() async {
    final nextNum = await InvoiceNumberGenerator.generateQuotationNumber();
    final duplicated = Quotation(
      id: nextNum,
      quotationNumber: nextNum,
      customerId: widget.quotation.customerId,
      customerName: widget.quotation.customerName,
      customerPhone: widget.quotation.customerPhone,
      customerAddress: widget.quotation.customerAddress,
      customerGst: widget.quotation.customerGst,
      customerEmail: widget.quotation.customerEmail,
      items: widget.quotation.items,
      subtotal: widget.quotation.subtotal,
      gstAmount: widget.quotation.gstAmount,
      total: widget.quotation.total,
      status: 'sent',
      validUntil: DateTime.now().add(const Duration(days: 15)),
      notes: widget.quotation.notes,
      otherChargeLabel: widget.quotation.otherChargeLabel,
      otherChargeAmount: widget.quotation.otherChargeAmount,
      isOtherChargeTaxable: widget.quotation.isOtherChargeTaxable,
      otherChargeGstPercent: widget.quotation.otherChargeGstPercent,
      terms: widget.quotation.terms,
      isRoundedOff: widget.quotation.isRoundedOff,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.insertQuotation(duplicated);
    SyncService().syncOnSave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicated as #${duplicated.quotationNumber}')));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: duplicated)),
    );
  }

  void _convertToInvoice() {
    // 1-Click Convert to Invoice (opens ManualBillingScreen pre-filled)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualBillingScreen(
          fromQuotation: widget.quotation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quotation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quotation Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateQuotation(q),
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
      bottomNavigationBar: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomAction(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              onTap: _duplicateQuotation,
            ),
            _buildBottomAction(
              icon: Icons.edit_note_rounded,
              label: 'Edit',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateQuotationScreen(quotation: q)),
                );
              },
            ),
            _buildBottomAction(
              icon: Icons.receipt_long_rounded,
              label: 'Invoice',
              onTap: _convertToInvoice,
            ),
            _buildBottomAction(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () async {
                final pdfBytes = await PdfService.generateQuotation(q);
                await Printing.sharePdf(bytes: pdfBytes, filename: '${q.quotationNumber}.pdf');
              },
            ),
            _buildBottomAction(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: () async {
                final pdfBytes = await PdfService.generateQuotation(q);
                await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: '${q.quotationNumber}.pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
