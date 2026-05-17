
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../models/sync_result.dart';
import '../../utils/image_helper.dart';
import '../../theme/app_theme.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  late TabController _tabController;
  List<CatalogItem> _products = [];
  List<CatalogItem> _services = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('tab')) {
      _tabController.index = args['tab'] as int;
    }
  }

  Future<void> _loadCatalog() async {
    final products = await _db.getCatalogItems(type: 'product');
    final services = await _db.getCatalogItems(type: 'service');
    setState(() {
      _products = products;
      _services = services;
      _isLoading = false;
    });
    _backgroundSync();
  }

  Future<void> _backgroundSync() async {
    try {
      await _sync.syncAll();
      final freshProducts = await _db.getCatalogItems(type: 'product');
      final freshServices = await _db.getCatalogItems(type: 'service');
      if (mounted) {
        setState(() {
          _products = freshProducts;
          _services = freshServices;
        });
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  Future<void> _syncCatalog() async {
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
        _loadCatalog();
      }
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => _AddItemDialog(
        type: _tabController.index == 0 ? 'product' : 'service',
      ),
    );

    if (result != null) {
      await _db.insertCatalogItem(result);
      _loadCatalog();
      await _sync.syncOnSave();
    }
  }

  Future<void> _editItem(CatalogItem item) async {
    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => _AddItemDialog(item: item),
    );

    if (result != null) {
      await _db.updateCatalogItem(result);
      _loadCatalog();
      await _sync.syncOnSave();
    }
  }

  Future<void> _deleteItem(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteCatalogItem(item.id);
      _loadCatalog();
      await _sync.syncOnSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
                  : const Icon(Icons.sync_rounded, color: AppTheme.accentColor),
              onPressed: _isSyncing ? null : _syncCatalog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondaryLight,
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Products'),
              Tab(icon: Icon(Icons.handyman_rounded), text: 'Services'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemGrid(_products, 'product'),
          _buildItemGrid(_services, 'service'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'catalog_fab',
        onPressed: _addItem,
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Product' : 'Add Service',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _buildItemGrid(List<CatalogItem> items, String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'product' ? Icons.inventory_2_outlined : Icons.handyman_outlined,
              size: 80,
              color: AppTheme.dividerColorLight,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'product' ? 'No products in catalog' : 'No services in catalog',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7, // Adjusted for taller premium cards
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _PremiumCatalogCard(
          item: items[index],
          onEdit: () => _editItem(items[index]),
          onDelete: () => _deleteItem(items[index]),
        );
      },
    );
  }
}

class _PremiumCatalogCard extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PremiumCatalogCard({
    required this.item, 
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isProduct = item.type == 'product';
    final accentColor = isProduct ? AppTheme.accentColor : const Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColorLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Theme.of(context).scaffoldBackgroundColor),
                    ImageHelper.buildImage(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: Icon(
                          isProduct ? Icons.inventory_2_rounded : Icons.handyman_rounded,
                          size: 48,
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                              ),
                              child: Icon(Icons.edit_rounded, size: 16, color: accentColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Info Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.category != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.category!,
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: accentColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              '+${item.gstPercent.toStringAsFixed(0)}% GST',
                              style: TextStyle(fontSize: 9, color: AppTheme.textSecondaryLight, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final CatalogItem? item;
  final String? type;

  const _AddItemDialog({this.item, this.type});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _type = 'product';
  double _gstPercent = 18.0;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _categoryController.text = widget.item!.category ?? '';
      _descriptionController.text = widget.item!.description ?? '';
      _imageUrlController.text = widget.item!.imageUrl ?? '';
      _type = widget.item!.type;
      _gstPercent = widget.item!.gstPercent;
    } else if (widget.type != null) {
      _type = widget.type!;
    }
    _imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
      if (image == null) return;

      setState(() => _isUploadingImage = true);
      final ext = image.path.split('.').last.toLowerCase();

      final presignedResp = await http.post(
        Uri.parse(ImageHelper.presignedUrlEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ext': ext, 'folder': 'catalog'}),
      );

      if (presignedResp.statusCode != 200) {
        throw Exception('Server returned ${presignedResp.statusCode}: ${presignedResp.body}');
      }
      final presignedData = jsonDecode(presignedResp.body);
      final uploadUrl = presignedData['uploadUrl'] as String;
      final publicUrl = presignedData['publicUrl'] as String;

      final bytes = await image.readAsBytes();
      final uploadResp = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/${ext == 'png' ? 'png' : 'jpeg'}'},
        body: bytes,
      );

      if (uploadResp.statusCode != 200) {
        throw Exception('S3 upload failed (${uploadResp.statusCode}): ${uploadResp.body}');
      }

      setState(() {
        _imageUrlController.text = publicUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded to AWS ✓'), backgroundColor: AppTheme.secondaryColor));
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text) ?? 0;
      final item = CatalogItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _type,
        name: _nameController.text,
        price: price,
        gstPercent: _gstPercent,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        updatedAt: DateTime.now(),
      );
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final isProduct = _type == 'product';
    final accentColor = isProduct ? AppTheme.accentColor : const Color(0xFF8B5CF6);
    final resolvedUrl = resolveImageUrl(_imageUrlController.text);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit ${isProduct ? 'Product' : 'Service'}' : 'New ${isProduct ? 'Product' : 'Service'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Image Uploader
                GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUpload,
                  child: Container(
                    height: 180,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColorLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isUploadingImage
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: accentColor),
                              const SizedBox(height: 12),
                              Text('Uploading to S3...', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                            ],
                          )
                        : resolvedUrl.isNotEmpty
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ImageHelper.buildImage(resolvedUrl, fit: BoxFit.cover),
                                  Container(color: Colors.black.withOpacity(0.3)),
                                  const Center(child: Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 48)),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppTheme.dividerColorLight),
                                  const SizedBox(height: 8),
                                  Text('Upload to AWS S3', style: TextStyle(color: AppTheme.textSecondaryLight, fontWeight: FontWeight.bold)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!isEdit) ...[
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Product'),
                          value: 'product',
                          groupValue: _type,
                          activeColor: AppTheme.accentColor,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Service'),
                          value: 'service',
                          groupValue: _type,
                          activeColor: const Color(0xFF8B5CF6),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.label_outline_rounded)),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price (₹) *', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<double>(
                        value: _gstPercent,
                        decoration: const InputDecoration(labelText: 'GST %'),
                        items: [0, 5, 12, 18, 28].map((g) => DropdownMenuItem(value: g.toDouble(), child: Text('$g%'))).toList(),
                        onChanged: (v) => setState(() => _gstPercent = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: accentColor), child: Text(isEdit ? 'Update' : 'Save Item'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
