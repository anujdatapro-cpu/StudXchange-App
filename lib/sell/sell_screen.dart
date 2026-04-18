import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = const [
    'Electronics',
    'Study Materials',
    'Furniture',
    'Stationery',
    'Sports',
    'Others',
  ];

  String _selectedCategory = 'Electronics';
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  XFile? _pickedImage;
  String? _uploadedImageUrl;

  Future<String> uploadImage(File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('items')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    final colors = context.appColors;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.secondaryText),
      prefixIcon:
          icon == null ? null : Icon(icon, color: colors.accent, size: 20),
      filled: true,
      fillColor: colors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isUploadingImage) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to add an item.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final category = _selectedCategory;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      var imageUrl = _uploadedImageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        final picked = _pickedImage;
        if (picked == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please pick an image.'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }

        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await uploadImage(File(picked.path));
          if (!mounted) return;
          setState(() => _uploadedImageUrl = imageUrl);
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }

      await FirebaseService.addItem(
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
        ownerEmail: email,
        category: category,
      );

      await FirebaseService.addNotification(
        userEmail: email,
        title: 'Your item has been listed successfully 🚀',
        message: 'Your item is live and ready for campus buyers.',
      );

      if (!mounted) return;

      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _pickedImage = null;
        _uploadedImageUrl = null;
        _selectedCategory = _categories.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item added successfully'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage || _isSubmitting) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _pickedImage = image;
      _isUploadingImage = true;
      _uploadedImageUrl = null;
    });

    try {
      final url = await uploadImage(File(image.path));

      if (!mounted) return;
      setState(() => _uploadedImageUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Add Item',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.accent.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.overlay,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.add, color: colors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'List a new item',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'It will appear instantly in the feed.',
                              style: TextStyle(color: colors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: colors.primaryText),
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('Title', icon: Icons.title),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: colors.primaryText),
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 6,
                  decoration: _decoration(
                    'Description',
                    icon: Icons.description_outlined,
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceController,
                  style: TextStyle(color: colors.primaryText),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('Price', icon: Icons.currency_rupee),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Price is required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Price must be a number';
                    if (parsed <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: colors.card,
                  iconEnabledColor: colors.secondaryText,
                  style: TextStyle(color: colors.primaryText),
                  decoration: _decoration('Category', icon: Icons.category),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedCategory = value);
                        },
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Category is required'
                      : null,
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.overlay,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _pickedImage == null
                            ? Icon(
                                Icons.image_outlined,
                                color: colors.accent,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item Image',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isUploadingImage
                                  ? 'Uploading...'
                                  : (_uploadedImageUrl != null
                                      ? 'Uploaded'
                                      : 'Pick from gallery'),
                              style: TextStyle(color: colors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed:
                            (_isUploadingImage || _isSubmitting) ? null : _pickAndUploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          disabledBackgroundColor: theme.disabledColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        child: _isUploadingImage
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text(
                                'Pick Image',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        (_isSubmitting || _isUploadingImage) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      disabledBackgroundColor: theme.disabledColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Add Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
