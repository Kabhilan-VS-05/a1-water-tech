import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/invoice_number_generator.dart';
import 'package:printing/printing.dart';
import 'bill_view_screen.dart';
import '../terms/terms_screen.dart';

class ManualBillingScreen extends StatefulWidget {
  final Quotation? fromQuotation;
  const ManualBillingScreen({super.key, this.fromQuotation});

  @override
  State<ManualBillingScreen> createState() => _ManualBillingScreenState();
}

class _ManualBillingScreenState extends State<ManualBillingScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();

  DateTime _invoiceDate = DateTime.now();
  String _invoiceNumber = '';
  String _poNumber = '';
  DateTime? _dueDate;

  Customer? _selectedCustomer;
  final List<BillItem> _cart = [];

  // Other charge
  String _otherChargeLabel = 'Other Charges';
  double _otherChargeAmount = 0.0;
  bool _isOtherChargeTaxable = false;
  double _otherChargeGstPercent = 18.0;

  // Terms & Notes
  String _termsAndConditions = '1. Payment due within 7 days of invoice date.\n2. Goods once sold are covered under standard 1-year warranty.';
  String _notes = '';
  bool _isRoundedOff = false;

  // Paid Info
  DateTime _paidDate = DateTime.now();
  double _paidAmount = 0.0;
  String _paymentMode = 'Cash';
  String _paidNote = '';
  bool _hasPaidInfo = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.fromQuotation != null) {
      final q = widget.fromQuotation!;
      _selectedCustomer = Customer(
        id: q.customerId ?? 'cust-${DateTime.now().millisecondsSinceEpoch}',
        name: q.customerName,
        phone: q.customerPhone,
        address: q.customerAddress,
        email: q.customerEmail,
        createdAt: DateTime.now(),
      );

      _cart.clear();
      for (final i in q.items) {
        _cart.add(BillItem(
          itemId: i.itemId,
          name: i.name,
          type: i.type,
          hsn: i.hsn,
          price: i.price,
          quantity: i.quantity,
          gstPercent: i.gstPercent,
          gstAmount: i.gstAmount,
          total: i.total,
          imageUrl: i.imageUrl,
        ));
      }

      _otherChargeLabel = q.otherChargeLabel ?? 'Other Charges';
      _otherChargeAmount = q.otherChargeAmount ?? 0.0;
      _isOtherChargeTaxable = q.isOtherChargeTaxable;
      _otherChargeGstPercent = q.otherChargeGstPercent ?? 18.0;
      _termsAndConditions = q.terms ?? _termsAndConditions;
      _notes = q.notes ?? '';
      _isRoundedOff = q.isRoundedOff;
    }

    try {
      _invoiceNumber = await InvoiceNumberGenerator.generateInvoiceNumber();
    } catch (_) {
      _invoiceNumber = 'BILL-${DateFormat('yyyyMMdd').format(DateTime.now())}-001';
    }

    if (mounted) setState(() {});
  }

  double get _subtotal => _cart.fold(0, (sum, i) => sum + (i.price * i.quantity));
  double get _taxTotal => _cart.fold(0, (sum, i) => sum + i.gstAmount);
  double get _otherChargeGst => (_isOtherChargeTaxable && _otherChargeAmount > 0)
      ? (_otherChargeAmount * _otherChargeGstPercent) / 100
      : 0.0;

  double get _grandTotal {
    final raw = _subtotal + _taxTotal + _otherChargeAmount + _otherChargeGst;
    return _isRoundedOff ? raw.roundToDouble() : raw;
  }

  double get _amountDue {
    final diff = _grandTotal - (_hasPaidInfo ? _paidAmount : 0.0);
    return diff < 0 ? 0.0 : diff;
  }

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

  Future<void> _pickProduct() async {
    final catalog = [
      ...await _db.getCatalogItems(type: 'product'),
      ...await _db.getCatalogItems(type: 'service'),
    ];
    if (!mounted) return;

    final item = await showModalBottomSheet<BillItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SelectBillProductSheet(catalog: catalog),
    );

    if (item != null) {
      setState(() => _cart.add(item));
    }
  }

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

  Future<void> _pickTerms() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const TermsConditionsScreen(
          isSelectionMode: true,
          documentType: 'Invoice',
        ),
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _termsAndConditions = picked);
    }
  }

  Future<void> _showPaidInfoModal() async {
    final amountCtrl = TextEditingController(text: _paidAmount > 0 ? _paidAmount.toString() : _grandTotal.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: _paidNote);
    String mode = _paymentMode;
    DateTime date = _paidDate;

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
              const Text('Paid Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paid Date: ${DateFormat('dd/MM/yyyy').format(date)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: InputDecoration(
                  labelText: 'Payment Mode',
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI / GPay / PhonePe', child: Text('UPI / GPay / PhonePe')),
                  DropdownMenuItem(value: 'Bank Transfer (NEFT/IMPS)', child: Text('Bank Transfer (NEFT/IMPS)')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                ],
                onChanged: (v) {
                  if (v != null) setSheetState(() => mode = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Note / Transaction Ref',
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
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
                      _paidDate = date;
                      _paidAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      _paymentMode = mode;
                      _paidNote = noteCtrl.text.trim();
                      _hasPaidInfo = _paidAmount > 0;
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

  Future<void> _generateInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer first.')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bill = Bill(
        id: _invoiceNumber,
        billNumber: _invoiceNumber,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer?.phone,
        customerAddress: _selectedCustomer?.address,
        customerGst: null,
        items: _cart,
        subtotal: _subtotal,
        gstAmount: _taxTotal,
        total: _grandTotal,
        paymentMode: _paymentMode,
        status: _amountDue <= 0 ? 'paid' : (_paidAmount > 0 ? 'partial' : 'pending'),
        createdAt: _invoiceDate,
        updatedAt: DateTime.now(),
      );

      await _db.insertBill(bill);
      _sync.syncOnSave();

      if (!mounted) return;

      final pdfBytes = await PdfService.generateInvoice(bill, customer: _selectedCustomer);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BillViewScreen(bill: bill)),
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: '${bill.billNumber}.pdf');
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save invoice: $e')));
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
        title: const Text('Make Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                          initialDate: _invoiceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _invoiceDate = picked);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice Date', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(DateFormat('dd/MM/yyyy').format(_invoiceDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Invoice No', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_invoiceNumber.isEmpty ? '-' : _invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due Date: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : '-'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text('PO No: ${_poNumber.isEmpty ? '-' : _poNumber}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card Rows List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // 1. BILL TO (CUSTOMER) Card
                _buildCardSection(
                  title: 'BILL TO (CUSTOMER)',
                  hasContent: _selectedCustomer != null,
                  content: _selectedCustomer != null
                      ? Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
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
                      ? Text(_termsAndConditions, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))
                      : null,
                  onAdd: _pickTerms,
                  onDelete: () => setState(() => _termsAndConditions = ''),
                ),
                const SizedBox(height: 12),

                // 5. PAID INFO Card
                _buildCardSection(
                  title: 'PAID INFO',
                  hasContent: _hasPaidInfo,
                  content: _hasPaidInfo
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$_paymentMode (${DateFormat('dd/MM/yy').format(_paidDate)})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('₹${_paidAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                          ],
                        )
                      : null,
                  onAdd: _showPaidInfoModal,
                  onDelete: () => setState(() {
                    _hasPaidInfo = false;
                    _paidAmount = 0.0;
                  }),
                ),
                const SizedBox(height: 12),

                // 6. ROUND OFF AMOUNT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ROUND OFF AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      Checkbox(
                        value: _isRoundedOff,
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
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
                        '₹${_amountDue.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _generateInvoice,
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
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle),
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface, size: 16),
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
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PRODUCTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                InkWell(
                  onTap: _pickProduct,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle),
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface, size: 16),
                  ),
                ),
              ],
            ),
          ),
          if (_cart.isNotEmpty) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cart.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _cart[i];
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
                        onPressed: () => setState(() => _cart.removeAt(i)),
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

// Sub components
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

class _SelectBillProductSheet extends StatefulWidget {
  final List<CatalogItem> catalog;
  const _SelectBillProductSheet({required this.catalog});

  @override
  State<_SelectBillProductSheet> createState() => _SelectBillProductSheetState();
}

class _SelectBillProductSheetState extends State<_SelectBillProductSheet> {
  String _search = '';
  CatalogItem? _selectedItem;

  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_selectedItem != null) {
      return FractionallySizedBox(
        heightFactor: 0.75,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedItem = null)),
            title: const Text('Add Invoice Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
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
                  decoration: InputDecoration(labelText: 'Quantity', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Price', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Description', hintText: 'Optional description (0/2000)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200))),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
                      final price = double.tryParse(_priceCtrl.text.trim()) ?? _selectedItem!.price;
                      final subtotal = price * qty;
                      final gstAmount = (subtotal * _selectedItem!.gstPercent) / 100;

                      final billItem = BillItem(
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

                      Navigator.pop(context, billItem);
                    },
                    child: const Text('Add To Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
}
