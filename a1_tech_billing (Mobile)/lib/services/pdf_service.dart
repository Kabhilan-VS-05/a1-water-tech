import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfService {
  static Future<Uint8List> generateInvoice(
    Bill bill, {
    Customer? customer,
  }) async {
    final pdf = Document();

    // Standard A4 Layout
    pdf.addPage(
      Page(
        pageFormat: PdfPageFormat.a4,
        margin: const EdgeInsets.all(40),
        build: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Divider(thickness: 2, color: PdfColors.indigo700),
            SizedBox(height: 20),
            _buildInvoiceMeta(bill),
            SizedBox(height: 20),
            _buildBillingSection(bill),
            SizedBox(height: 30),
            _buildItemsTable(bill),
            SizedBox(height: 20),
            _buildSummaryAndNotes(bill),
            Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A1 WATER TECH',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Advanced Water Purification Solutions',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
            SizedBox(height: 12),
            _infoText('116, Kumarasamy Puram, Ganapathi Palayam'),
            _infoText('Erode, Tamil Nadu - 638153'),
            _infoText('GSTIN: 33AAAAA0000A1Z5 (Sample)'),
            _infoText('Phone: +91 87603 51341'),
            _infoText('Email: support@a1watertech.com'),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: PdfColors.indigo700, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'INVOICE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PdfColors.indigo700,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildInvoiceMeta(Bill bill) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metaColumn('INVOICE NO', bill.billNumber),
        _metaColumn('DATE', DateFormat('dd-MMM-yyyy').format(bill.createdAt)),
        _metaColumn('PAYMENT', bill.paymentMode.toUpperCase()),
        _metaColumn('STATUS', bill.status.toUpperCase(), 
          color: bill.status == 'paid' ? PdfColors.green700 : PdfColors.orange700),
      ],
    );
  }

  static Widget _buildBillingSection(Bill bill) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BILL TO:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PdfColors.grey700),
          ),
          SizedBox(height: 6),
          Text(
            bill.customerName.toUpperCase(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (bill.customerPhone != null) ...[
            SizedBox(height: 2),
            Text('Contact: ${bill.customerPhone}', style: const TextStyle(fontSize: 11)),
          ],
          if (bill.customerAddress != null) ...[
            SizedBox(height: 4),
            Text(
              bill.customerAddress!,
              style: const TextStyle(fontSize: 11, lineSpacing: 2),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildItemsTable(Bill bill) {
    const tableHeaders = ['SL', 'DESCRIPTION', 'QTY', 'UNIT PRICE', 'GST %', 'AMOUNT'];

    return TableHelper.fromTextArray(
      border: null,
      headerStyle: TextStyle(color: PdfColors.white, fontWeight: FontWeight.bold, fontSize: 10),
      headerDecoration: const BoxDecoration(color: PdfColors.indigo700),
      rowDecoration: const BoxDecoration(border: Border(bottom: BorderSide(color: PdfColors.grey300, width: .5))),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerRight,
        3: Alignment.centerRight,
        4: Alignment.centerRight,
        5: Alignment.centerRight,
      },
      headers: tableHeaders,
      data: List<List<dynamic>>.generate(
        bill.items.length,
        (index) {
          final item = bill.items[index];
          return [
            index + 1,
            item.name,
            item.quantity,
            'Rs. ${item.price.toStringAsFixed(2)}',
            '${item.gstPercent}%',
            'Rs. ${item.total.toStringAsFixed(2)}',
          ];
        },
      ),
    );
  }

  static Widget _buildSummaryAndNotes(Bill bill) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TERMS & CONDITIONS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              _bulletPoint('Goods once sold cannot be taken back or exchanged.'),
              _bulletPoint('Warranty as per manufacturer terms.'),
              _bulletPoint('Subject to Erode Jurisdiction.'),
              SizedBox(height: 20),
              Text('DECLARATION:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text(
                'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
                style: const TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        SizedBox(width: 40),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _summaryRow('Subtotal', bill.subtotal),
              _summaryRow('Tax (GST)', bill.gstAmount),
              Divider(color: PdfColors.indigo700),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: PdfColors.indigo50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Rs. ${bill.total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: PdfColors.indigo700),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Text('For A1 WATER TECH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              Divider(thickness: 1, color: PdfColors.grey400),
              Text('Authorized Signatory', style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Divider(color: PdfColors.grey300),
          SizedBox(height: 8),
          Text(
            'This is a computer generated invoice and does not require a physical signature.',
            style: const TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          SizedBox(height: 4),
          Text(
            'Thank you for your business! Visit us again at www.a1watertech.com',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: PdfColors.indigo700),
          ),
        ],
      ),
    );
  }

  static Widget _infoText(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, color: PdfColors.grey800));
  }

  static Widget _metaColumn(String label, String value, {PdfColor? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: FontWeight.bold)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  static Widget _summaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text('Rs. ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static Widget _bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: const TextStyle(fontSize: 8)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 8, color: PdfColors.grey700))),
      ],
    );
  }
}
