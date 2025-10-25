// lib/screen/admin/kelola_artikel_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk deteksi Web
import 'artikel_detail_page.dart'; // <-- Impor halaman detail baru

class KelolaArtikelPage extends StatefulWidget {
  const KelolaArtikelPage({super.key});

  @override
  State<KelolaArtikelPage> createState() => _KelolaArtikelPageState();
}

class _KelolaArtikelPageState extends State<KelolaArtikelPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // --- Fungsi Tampilkan List Artikel ---
  Widget _buildArtikelList() {
    return StreamBuilder<QuerySnapshot>(
      // --- BEDA: Ambil dari koleksi 'artikel' ---
      stream: _firestore.collection('artikel').snapshots(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi error.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada data artikel.'));
        }

        final artikelDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: artikelDocs.length,
          itemBuilder: (context, index) {
            final doc = artikelDocs[index];
            final artikel = doc.data() as Map<String, dynamic>;
            // --- BEDA: Hanya satu URL, bukan list ---
            final String? imageUrl = artikel['imageUrl']; 
            final String docId = doc.id;

            return Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 2,
              child: ListTile(
                // --- BEDA: Logika thumbnail ---
                leading: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
                // --- BEDA: 'nama' jadi 'judul' ---
                title: Text(artikel['judul'] ?? 'Tanpa Judul'),
                subtitle: Text(
                  artikel['deskripsi'] ?? 'Tanpa deskripsi',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Aksi onTap untuk "Lihat Detail"
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // --- BEDA: Panggil ArtikelDetailPage ---
                      builder: (ctx) => ArtikelDetailPage(doc: doc), 
                    ),
                  );
                },

                // Tombol Edit dan Delete
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () {
                        _showAddFormSheet(context, existingData: doc);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // --- BEDA: Kirim satu URL saja ---
                        _deleteArtikel(docId, imageUrl); 
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Fungsi Hapus Data ---
  Future<void> _deleteArtikel(String docId, String? imageUrl) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus artikel ini?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == null || !confirmed) return;

    try {
      // --- BEDA: Hapus dari koleksi 'artikel' ---
      await _firestore.collection('artikel').doc(docId).delete();
      
      // Peringatan: Gambar di Cloudinary TIDAK terhapus.
      if(imageUrl != null) {
        debugPrint('Data Firestore terhapus. Gambar di Cloudinary (URL: $imageUrl) masih ada.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil dihapus.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Fungsi Form Tambah / Edit ---
  void _showAddFormSheet(BuildContext context, {DocumentSnapshot? existingData}) {
    final bool isEdit = existingData != null;
    final String docId = isEdit ? existingData.id : '';

    final formKey = GlobalKey<FormState>();
    // --- BEDA: Controller ---
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    // (Harga dan Lokasi dihapus)

    // --- BEDA: Hanya satu gambar ---
    XFile? newImage; // (Bukan List<File>)
    bool isLoading = false;

    // Isi form jika mode Edit
    if (isEdit) {
      final data = existingData.data() as Map<String, dynamic>;
      judulController.text = data['judul'] ?? '';
      deskripsiController.text = data['deskripsi'] ?? '';
      // Kita tidak mengelola edit gambar untuk saat ini
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            // --- BEDA: Fungsi pick SATU gambar ---
            Future<void> pickImage() async {
              if(isEdit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit gambar belum didukung.')),
                );
                return;
              }
              // Ambil satu gambar
              final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedFile == null) return;
              setStateModal(() {
                newImage = pickedFile;
              });
            }

            // --- Fungsi Submit Data ---
            Future<void> submitData() async {
              // --- BEDA: Validasi satu gambar ---
              if (!formKey.currentState!.validate() || (!isEdit && newImage == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi semua field dan pilih 1 gambar.')),
                );
                return;
              }

              setStateModal(() => isLoading = true);

              final cloudinary = CloudinaryPublic(
                'do1f1njjy', // <--- GANTI JIKA BEDA
                'axgi2x1n', // <--- GANTI JIKA BEDA
                cache: false,
              );

              try {
                // --- BEDA: Data lebih simpel ---
                Map<String, dynamic> dataToSave = {
                  'judul': judulController.text,
                  'deskripsi': deskripsiController.text,
                };

                // Logika Upload hanya jika TAMBAH BARU
                if (!isEdit && newImage != null) {
                  // --- BEDA: Upload satu gambar (logika web/mobile) ---
                  CloudinaryResponse response;
                  // Gunakan fromFile untuk web dan mobile agar tidak bergantung pada fromBytes
                  response = await cloudinary.uploadFile(
                    CloudinaryFile.fromFile(
                      newImage!.path,
                      resourceType: CloudinaryResourceType.Image,
                      folder: 'artikel_app',
                    ),
                  );
                  // Simpan satu URL
                  dataToSave['imageUrl'] = response.secureUrl;
                  dataToSave['createdAt'] = Timestamp.now();
                }

                // Logika Simpan (Edit vs Tambah)
                if (isEdit) {
                  await _firestore.collection('artikel').doc(docId).update(dataToSave);
                } else {
                  await _firestore.collection('artikel').add(dataToSave);
                }

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Artikel berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}.')),
                );
              } catch (e) {
                setStateModal(() => isLoading = false);
                debugPrint('Error saat upload/simpan: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan data: $e')),
                );
              }
            }

            // --- Tampilan Form ---
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16, left: 16, right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Data Artikel' : 'Tambah Artikel Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 16),
                      // --- BEDA: Form Fields ---
                      TextFormField(
                        controller: judulController,
                        decoration: const InputDecoration(labelText: 'Judul Artikel', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Judul tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: deskripsiController,
                        decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                        maxLines: 5, // Deskripsi artikel biasanya lebih panjang
                        validator: (val) => val!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                      ),
                      // (Harga dan Lokasi dihapus)
                      const SizedBox(height: 16),
                      
                      // Sembunyikan jika mode Edit
                      if (!isEdit) ...[
                        const Text('Gambar (Wajib, 1 gambar):'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                          onPressed: pickImage, // Panggil fungsi _pickImage (singular)
                        ),
                        // --- BEDA: Preview satu gambar ---
                        if (newImage != null)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 8),
                            child: kIsWeb
                              ? Image.network(newImage!.path, width: 100, height: 100, fit: BoxFit.cover)
                              : Image.file(File(newImage!.path), width: 100, height: 100, fit: BoxFit.cover),
                          ),
                      ],
                      if (isEdit)
                        const Text(
                          'Info: Edit gambar belum didukung.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: Text(isEdit ? 'Update' : 'Simpan'),
                                onPressed: submitData,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Build Tampilan Utama ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- BEDA: Tema ---
        title: const Text('Kelola Artikel', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green.shade700,
      ),
      // --- BEDA: Panggil _buildArtikelList ---
      body: _buildArtikelList(), 
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFormSheet(context);
        },
        foregroundColor: Colors.white,
        // --- BEDA: Tema ---
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }
}