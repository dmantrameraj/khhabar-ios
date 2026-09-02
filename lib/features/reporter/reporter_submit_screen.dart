import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../data/models/category_node.dart';
import '../home/home_screen.dart' show topCategoriesProvider;

/// The reporter's "file a story" form — title, one photo, plain body
/// text, and a category. Minimal by design (no tags/SEO/drafts/gallery,
/// matching the scoped-down v1 of this feature) — submits straight to
/// 'pending', same as the website's "Submit for approval" action. See
/// ReporterApiController::submit() for the backend side.
class ReporterSubmitScreen extends ConsumerStatefulWidget {
  const ReporterSubmitScreen({super.key});

  @override
  ConsumerState<ReporterSubmitScreen> createState() => _ReporterSubmitScreenState();
}

class _ReporterSubmitScreenState extends ConsumerState<ReporterSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  CategoryNode? _category;
  File? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach a photo for this story.')));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a category.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(reporterRepositoryProvider).submit(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            categoryId: _category!.id,
            imagePath: _image!.path,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for approval.')),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit. Please check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(topCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('नई खबर भेजें')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _submitting ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('फ़ोटो जोड़ें', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'हेडलाइन', border: OutlineInputBorder()),
              maxLength: 255,
              validator: (v) => (v == null || v.trim().length < 5) ? 'कम से कम 5 अक्षर लिखें' : null,
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<CategoryNode>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'श्रेणी चुनें', border: OutlineInputBorder()),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'श्रेणी चुनें' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('श्रेणियाँ लोड नहीं हो सकीं। $err', style: TextStyle(color: Colors.red.shade700)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'खबर लिखें', border: OutlineInputBorder(), alignLabelWithHint: true),
              minLines: 8,
              maxLines: 20,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'खबर लिखें' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('स्वीकृति हेतु भेजें'),
            ),
          ],
        ),
      ),
    );
  }
}
