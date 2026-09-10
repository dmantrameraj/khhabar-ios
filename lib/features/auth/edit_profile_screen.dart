import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';

/// Name, phone, and avatar only — matches what the backend actually
/// supports (UserModel::updateProfile()/updateAvatar(), the same methods
/// the website's own profile-edit screen calls). Email isn't editable
/// here (it's the login identifier); nothing else on AuthUser has a
/// write path yet.
class EditProfileScreen extends ConsumerStatefulWidget {
  final AuthUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  File? _newAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया अपना नाम लिखें।')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: name,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            avatarPath: _newAvatar?.path,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('प्रोफाइल अपडेट हो गई।')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('सेव नहीं हो सकी। कृपया दोबारा कोशिश करें।')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('प्रोफाइल एडिट करें')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.navy,
                    backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!)
                        : (widget.user.avatar != null ? NetworkImage(widget.user.avatar!) : null) as ImageProvider?,
                    child: _newAvatar == null && widget.user.avatar == null
                        ? Text(
                            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppTheme.accent,
                      child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'नाम', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'फ़ोन नंबर (वैकल्पिक)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('सेव करें'),
          ),
        ],
      ),
    );
  }
}
