// lib/screen/user/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../provider/auth_provider.dart'; // Impor AuthProvider

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Global Keys untuk validasi form
  final _nameFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controllers untuk input teks
  final _nameController = TextEditingController();
  final _currentPasswordEmailController = TextEditingController(); // Password saat ini (untuk ganti email)
  final _newEmailController = TextEditingController();
  final _currentPasswordPassController = TextEditingController(); // Password saat ini (untuk ganti pass)
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State untuk visibilitas password
  bool _obscureCurrentEmail = true;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // Ambil data user saat ini
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Isi field nama dengan nama saat ini (jika ada)
    // (Kita tidak bisa langsung ambil dari Firestore di initState tanpa async)
    // Jadi, kita ambil dari Auth display name (jika ada), atau user bisa isi manual
     _nameController.text = _currentUser?.displayName ?? '';
     // Jika ingin ambil dari Firestore, perlu FutureBuilder di widget build
  }

  @override
  void dispose() {
    // Selalu dispose controllers!
    _nameController.dispose();
    _currentPasswordEmailController.dispose();
    _newEmailController.dispose();
    _currentPasswordPassController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Fungsi Helper untuk Tampilkan Error ---
  void _showErrorSnackBar(String message) {
     if (!mounted) return; // Cek jika widget masih ada
     ScaffoldMessenger.of(context).hideCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
     );
  }
   // --- Fungsi Helper untuk Tampilkan Sukses ---
  void _showSuccessSnackBar(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).hideCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
     );
  }

  // --- Fungsi Logika untuk Update ---

  // Update Nama
  Future<void> _updateName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.updateUserName(
      newName: _nameController.text.trim(),
      onError: _showErrorSnackBar,
    );
    if(success) {
      _showSuccessSnackBar("Nama berhasil diperbarui.");
    }
  }

  // Update Email
  Future<void> _updateEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 1. Re-autentikasi dulu
    bool reauthSuccess = await authProvider.reauthenticateUser(
      currentPassword: _currentPasswordEmailController.text, // JANGAN di-trim
      onError: _showErrorSnackBar,
    );

    // 2. Jika re-auth berhasil, baru update email
    if (reauthSuccess) {
      bool updateSuccess = await authProvider.updateUserEmail(
        newEmail: _newEmailController.text.trim(),
        onError: _showErrorSnackBar,
      );
      if(updateSuccess) {
         _showSuccessSnackBar("Email berhasil diperbarui. Silakan login ulang jika diminta.");
         // Kosongkan field setelah sukses
         _currentPasswordEmailController.clear();
         _newEmailController.clear();
      }
    }
  }

  // Update Password
  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Re-autentikasi dulu
    bool reauthSuccess = await authProvider.reauthenticateUser(
      currentPassword: _currentPasswordPassController.text, // JANGAN di-trim
      onError: _showErrorSnackBar,
    );

    // 2. Jika re-auth berhasil, baru update password
    if (reauthSuccess) {
      bool updateSuccess = await authProvider.updateUserPassword(
        newPassword: _newPasswordController.text, // JANGAN di-trim
        onError: _showErrorSnackBar,
      );
       if(updateSuccess) {
         _showSuccessSnackBar("Password berhasil diperbarui.");
         // Kosongkan field setelah sukses
         _currentPasswordPassController.clear();
         _newPasswordController.clear();
         _confirmPasswordController.clear();
       }
    }
  }


  // --- Tampilan UI ---
  @override
  Widget build(BuildContext context) {
    // Ambil status loading dari provider
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: GestureDetector( // Untuk dismiss keyboard saat klik di luar form
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Bagian Ganti Nama ---
            _buildSectionTitle('Ubah Nama'),
            Form(
              key: _nameFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _updateName,
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Nama'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // --- Bagian Ganti Email ---
            _buildSectionTitle('Ubah Email'),
            Form(
              key: _emailFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordEmailController,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                       suffixIcon: IconButton(
                         icon: Icon(_obscureCurrentEmail ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscureCurrentEmail = !_obscureCurrentEmail),
                       ),
                    ),
                    obscureText: _obscureCurrentEmail,
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan password saat ini' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newEmailController,
                    decoration: const InputDecoration(labelText: 'Email Baru'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Masukkan email baru yang valid';
                      }
                      if (value == _currentUser?.email) {
                        return 'Email baru tidak boleh sama dengan email lama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                     onPressed: isLoading ? null : _updateEmail,
                     child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Email Baru'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // --- Bagian Ganti Password ---
            _buildSectionTitle('Ubah Password'),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordPassController,
                    decoration: InputDecoration(
                       labelText: 'Password Saat Ini',
                       suffixIcon: IconButton(
                         icon: Icon(_obscureCurrentPass ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                       ),
                    ),
                    obscureText: _obscureCurrentPass,
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan password saat ini' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                       labelText: 'Password Baru',
                        suffixIcon: IconButton(
                         icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                       ),
                    ),
                    obscureText: _obscureNewPass,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password baru minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                   const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                       labelText: 'Konfirmasi Password Baru',
                       suffixIcon: IconButton(
                         icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                       ),
                    ),
                    obscureText: _obscureConfirmPass,
                     validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                     onPressed: isLoading ? null : _updatePassword,
                     child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Password Baru'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk judul bagian
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}