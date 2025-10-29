import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Untuk ambil gambar
import 'package:cloudinary_public/cloudinary_public.dart'; // Untuk upload
import '../../provider/auth_provider.dart';
// import '../../provider/theme_provider.dart'; // <-- IMPOR INI SUDAH DIHAPUS
import '../login_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // Untuk loading saat upload foto

  // --- Fungsi untuk Pilih & Upload Foto Profil ---
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || _userId == null) return;

    setState(() => _isUploading = true);

    // --- GANTI DENGAN KREDENSIAL CLOUDINARY ANDA ---
    final cloudinary = CloudinaryPublic('do1f1njjy', 'axgi2x1n', cache: false); // <-- GANTI JIKA BEDA
    // ----------------------------------------------

    try {
      // Upload ke Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(pickedFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'profile_pics', // Folder khusus foto profil
            // Jadikan public ID = user ID agar mudah diganti/dicari
            publicId: _userId,
        ),
      );

      String imageUrl = response.secureUrl;

      // Update URL foto di Firestore
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'profileImageUrl': imageUrl,
      });

      setState(() => _isUploading = false);
      if (!context.mounted) return; // Cek mounted sebelum panggil ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui.'), backgroundColor: Colors.green),
      );

    } catch (e) {
      setState(() => _isUploading = false);
      if (!context.mounted) return; // Cek mounted sebelum panggil ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupload foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- HAPUS PANGGILAN themeProvider ---
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final themeProvider = Provider.of<ThemeProvider>(context);
    // --- AKHIR PENGHAPUSAN ---


    if (_userId == null) {
      // Seharusnya tidak terjadi jika user sudah login
      return const Center(child: Text('User tidak ditemukan.'));
    }

    // Gunakan StreamBuilder untuk ambil data user secara real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_userId).snapshots(),
      builder: (context, snapshot) {
        // Handle loading & error
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Gagal memuat data profil.'));
        }

        // Ambil data user
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String nama = userData['nama'] ?? 'Pengguna Baru';
        final String email = userData['email'] ?? 'Tidak ada email';
        final String? profileImageUrl = userData['profileImageUrl'];

        // UI Profil
        return Container( // Bungkus dengan Container putih
          color: Colors.white, 
          child: ListView( // Gunakan ListView agar bisa scroll jika konten banyak
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Bagian Foto Profil ---
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      // Tampilkan foto profil atau ikon default
                      backgroundImage: (profileImageUrl != null)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: (profileImageUrl == null && !_isUploading) // Tampilkan ikon jika tidak ada foto & tidak sedang upload
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null, // Kosongkan jika ada foto
                    ),
                    // Indikator loading saat upload
                    if (_isUploading)
                      const Positioned(
                        bottom: 4, right: 4,
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      ),
                    // Tombol Edit Foto (jika tidak sedang upload)
                    if (!_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                            onPressed: _pickAndUploadImage,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Nama & Email ---
              Center(
                child: Text(nama, style: Theme.of(context).textTheme.headlineSmall),
              ),
              Center(
                child: Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ),

              // --- Tombol Edit Profil ---
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profil'),
                  onPressed: () {
                    // Navigasi ke halaman edit profil
                    Navigator.of(context).pushNamed('/edit-profile');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade800, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // --- AKHIR Tombol Edit Profil ---

              const SizedBox(height: 24),
              const Divider(),

              // --- Tombol ke Favorit ---
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Wisata Favorit Saya'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Pindah ke tab Favorite (indeks 2)
                  try {
                    DefaultTabController.of(context).animateTo(2);
                  } catch (e) {
                     debugPrint("Error navigating to favorites: $e");
                  }
                },
              ),

              // --- HAPUS SWITCH TEMA ---
              // SwitchListTile(...),
              // --- AKHIR PENGHAPUSAN ---

              const Divider(),

              // --- Tombol Logout ---
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  authProvider.signOut();
                  // Navigasi ke login & hapus history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => LoginPage()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 80), // Padding bawah
            ],
          ),
        );
      },
    );
  }
}