import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _photoUrlController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final names = (user?.displayName ?? '').split(' ');
    
    // Handle cases where display name might be empty or have multiple parts
    String firstName = '';
    String lastName = '';
    
    if (names.isNotEmpty) {
      firstName = names.first;
      if (names.length > 1) {
        lastName = names.sublist(1).join(' ');
      }
    }

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _photoUrlController = TextEditingController(text: user?.photoURL ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final photoUrl = _photoUrlController.text.trim();

      await context.read<AuthService>().updateProfile(
            firstName: firstName,
            lastName: lastName,
            photoUrl: photoUrl.isEmpty ? null : photoUrl,
          );
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primaryContainer,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Icon(Icons.person_rounded,
                                  size: 60, color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(Icons.camera_alt_rounded,
                              size: 20, color: colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter first name'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter last name'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText:
                        'Phone number update requires re-authentication.',
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _photoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Profile Photo URL',
                    prefixIcon: Icon(Icons.link_rounded),
                    helperText: 'Enter a valid image URL',
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _updateProfile,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_loading ? 'Saving Changes...' : 'Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
