import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool isSelectionMode;
  final String documentType; // 'Quotation' or 'Invoice' or 'Purchase Order'
  final Function(String selectedTerms)? onSelected;

  const TermsConditionsScreen({
    super.key,
    this.isSelectionMode = false,
    this.documentType = 'Quotation',
    this.onSelected,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, String>> _termsList = [];
  bool _isLoading = true;
  String _selectedTermText = '';

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);

    final saved = await _db.getSetting('terms_and_conditions_list');
    if (saved != null && saved.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        _termsList = decoded.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (e) {
        _termsList = _defaultTerms();
      }
    } else {
      _termsList = _defaultTerms();
      await _db.setSetting('terms_and_conditions_list', jsonEncode(_termsList));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, String>> _defaultTerms() {
    return [
      {
        'type': 'Quotation',
        'title': 'Standard Quotation Terms',
        'text': '1. Prices are valid for 15 days from quotation date.\n2. Standard delivery & installation included.\n3. Taxes charged as applicable at invoice generation.',
      },
      {
        'type': 'Invoice',
        'title': 'Standard Invoice Terms',
        'text': '1. Payment due within 7 days of invoice date.\n2. Goods once sold are covered under standard 1-year warranty.\n3. Interest @ 18% per annum applicable on delayed payments.',
      },
    ];
  }

  Future<void> _saveTermsList() async {
    await _db.setSetting('terms_and_conditions_list', jsonEncode(_termsList));
  }

  Future<void> _showAddTermDialog() async {
    String type = widget.documentType;
    final textCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Terms and condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  labelText: 'TYPE',
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'Quotation', child: Text('Quotation')),
                  DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                  DropdownMenuItem(value: 'Purchase Order', child: Text('Purchase Order')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (v) {
                  if (v != null) setSheetState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Terms and condition',
                  hintText: 'Enter terms and conditions text...',
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
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;

                    setState(() {
                      _termsList.add({
                        'type': type,
                        'title': '$type Terms',
                        'text': text,
                      });
                    });
                    _saveTermsList();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _termsList.where((t) => t['type'] == widget.documentType || widget.documentType == 'All').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isSelectionMode ? 'Select Terms and C...' : 'Terms and Conditions',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Term',
            onPressed: _showAddTermDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Theme.of(context).cardColor,
                  child: Center(
                    child: Text(
                      widget.documentType,
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'You don\'t have any terms and conditions',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final term = filtered[i];
                            final isSelected = _selectedTermText == term['text'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.teal : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Material(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.hardEdge,
                                child: ListTile(
                                title: Text(term['title'] ?? 'Terms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(term['text'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4)),
                                ),
                                trailing: widget.isSelectionMode
                                    ? Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isSelected ? Colors.teal : Colors.grey,
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() => _termsList.remove(term));
                                          _saveTermsList();
                                        },
                                      ),
                                onTap: () {
                                  if (widget.isSelectionMode) {
                                    setState(() => _selectedTermText = term['text'] ?? '');
                                  }
                                },
                              ),
                            ),
                          );
                          },
                        ),
                ),
                if (widget.isSelectionMode)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E293B),
                    width: double.infinity,
                    child: SafeArea(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
                          if (widget.onSelected != null) {
                            widget.onSelected!(_selectedTermText);
                          }
                          Navigator.pop(context, _selectedTermText);
                        },
                        child: const Text('DONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
