import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../widgets/loading_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _licenseCtl = TextEditingController();
  final _specializationCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  Uint8List? _newPictureBytes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameCtl.text = user.firstName;
      _lastNameCtl.text = user.lastName;
      _phoneCtl.text = user.phoneNumber ?? '';
      _addressCtl.text = user.address ?? '';
      _licenseCtl.text = user.licenseNumber ?? '';
      _specializationCtl.text = user.specialization ?? '';
      _bioCtl.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _licenseCtl.dispose();
    _specializationCtl.dispose();
    _bioCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked != null) {
      setState(() => _newPictureBytes = null);
      final bytes = await picked.readAsBytes();
      setState(() => _newPictureBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      firstName: _firstNameCtl.text.trim(),
      lastName: _lastNameCtl.text.trim(),
      phoneNumber: _phoneCtl.text.trim(),
      address: _addressCtl.text.trim(),
      licenseNumber: _licenseCtl.text.trim(),
      specialization: _specializationCtl.text.trim(),
      bio: _bioCtl.text.trim(),
      profilePictureBytes: _newPictureBytes,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.translate(en: 'Profile updated', rw: 'Ibiwanga byahinduwe')), backgroundColor: GaraTheme.accent),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDoctor = user?.isDoctor ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.translate(en: 'Edit Profile', rw: 'Hindura ibiwanga'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: (_newPictureBytes != null)
                      ? MemoryImage(_newPictureBytes!) as ImageProvider
                      : ((user?.profilePicture != null)
                          ? NetworkImage('${ApiConfig.baseUrl.replaceAll('/api', '')}media/${user!.profilePicture!}')
                          : null),
                  child: _newPictureBytes == null && user?.profilePicture == null
                      ? const Icon(Icons.camera_alt, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _pickImage, child: Text(LocalizationService.translate(en: 'Change photo', rw: 'Hindura ifoto'))),
              const SizedBox(height: 24),
              TextFormField(controller: _firstNameCtl, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'First name', rw: 'Izina'))),
              const SizedBox(height: 16),
              TextFormField(controller: _lastNameCtl, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'Last name', rw: 'Iryo'))),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneCtl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'Phone', rw: 'Telefone'))),
              const SizedBox(height: 16),
              TextFormField(controller: _addressCtl, maxLines: 2, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'Address', rw: 'Aho utuye'))),
              if (isDoctor) ...[
                const SizedBox(height: 16),
                TextFormField(controller: _licenseCtl, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'License number', rw: 'Indangantego'))),
                const SizedBox(height: 16),
                TextFormField(controller: _specializationCtl, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'Specialization', rw: 'Ubuhanga'))),
                const SizedBox(height: 16),
                TextFormField(controller: _bioCtl, maxLines: 3, decoration: InputDecoration(labelText: LocalizationService.translate(en: 'Bio', rw: 'Ibiwanga'))),
              ],
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => LoadingButton(
                  loading: auth.loading,
                  label: LocalizationService.translate(en: 'Save', rw: 'Bika'),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
