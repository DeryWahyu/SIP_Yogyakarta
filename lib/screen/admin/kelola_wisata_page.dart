// lib/screen/admin/kelola_wisata_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'wisata_detail_page.dart'; // <-- BARU: Impor halaman detail

class KelolaWisataPage extends StatefulWidget {
  const KelolaWisataPage({super.key});

  @override
  State<KelolaWisataPage> createState() => _KelolaWisataPageState();
}

class _KelolaWisataPageState extends State<KelolaWisataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Widget _buildWisataList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tempat_wisata').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi error.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada data tempat wisata.'));
        }

        final wisataDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: wisataDocs.length,
          itemBuilder: (context, index) {
            final doc = wisataDocs[index];
            final wisata = doc.data() as Map<String, dynamic>;
            final List<dynamic> imageUrls = wisata['imageUrls'] ?? [];
            final String docId = doc.id; 

            return Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 2,
              child: ListTile(
                leading: imageUrls.isNotEmpty
                    ? Image.network(
                        imageUrls[0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
                title: Text(wisata['nama'] ?? 'Tanpa Nama'),
                subtitle: Text(
                  wisata['deskripsi'] ?? 'Tanpa deskripsi',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // --- BARU: Aksi onTap untuk "Lihat Detail" ---
                onTap: () {
                  // Navigasi ke halaman detail saat di-klik
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => WisataDetailPage(doc: doc),
                    ),
                  );
                },
                // --- AKHIR BLOK BARU ---

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
                        _deleteWisata(docId, imageUrls);
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

  Future<void> _deleteWisata(String docId, List<dynamic> imageUrls) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
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

    if (confirmed == null || !confirmed) {
      return;
    }

    try {
      await _firestore.collection('tempat_wisata').doc(docId).delete();
      debugPrint('Data Firestore terhapus. Gambar di Cloudinary (URLs: $imageUrls) masih ada.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dihapus.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddFormSheet(BuildContext context, {DocumentSnapshot? existingData}) {
    final bool isEdit = existingData != null;
    final String docId = isEdit ? existingData.id : '';

    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController();
    final deskripsiController = TextEditingController();
    final hargaController = TextEditingController();
    final lokasiController = TextEditingController();

    List<File> newImages = []; 
    bool isLoading = false;

    if (isEdit) {
      final data = existingData.data() as Map<String, dynamic>;
      namaController.text = data['nama'] ?? '';
      deskripsiController.text = data['deskripsi'] ?? '';
      hargaController.text = data['harga'] ?? '';
      lokasiController.text = data['lokasi'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            Future<void> pickImages() async {
              if(isEdit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit gambar belum didukung. Hapus dan buat baru jika ingin ganti gambar.')),
                );
                return;
              }
              final List<XFile> pickedFiles = await _picker.pickMultiImage();
              if (pickedFiles.isEmpty) return;
              setStateModal(() {
                newImages = pickedFiles.map((xfile) => File(xfile.path)).toList();
              });
            }

            Future<void> submitData() async {
              if (!formKey.currentState!.validate() || (!isEdit && newImages.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi semua field dan pilih minimal 1 gambar (saat menambah baru).')),
                );
                return;
              }

              setStateModal(() => isLoading = true);

              // GANTI dengan kredensial Cloudinary Anda
              final cloudinary = CloudinaryPublic(
                'do1f1njjy', // <--- GANTI JIKA BEDA
                'axgi2x1n', // <--- GANTI JIKA BEDA
                cache: false,
              );

              try {
                Map<String, dynamic> dataToSave = {
                  'nama': namaController.text,
                  'deskripsi': deskripsiController.text,
                  'harga': hargaController.text,
                  'lokasi': lokasiController.text,
                };

                if (!isEdit) {
                  List<String> imageUrls = [];
                  for (File imageFile in newImages) {
                    final response = await cloudinary.uploadFile(
                      CloudinaryFile.fromFile(
                        imageFile.path,
                        resourceType: CloudinaryResourceType.Image,
                        folder: 'wisata_app',
                      ),
                    );
                    imageUrls.add(response.secureUrl);
                  }
                  dataToSave['imageUrls'] = imageUrls;
                  dataToSave['createdAt'] = Timestamp.now();
                }

                if (isEdit) {
                  await _firestore.collection('tempat_wisata').doc(docId).update(dataToSave);
                } else {
                  await _firestore.collection('tempat_wisata').add(dataToSave);
                }

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}.')),
                );
              } catch (e) {
                setStateModal(() => isLoading = false);
                debugPrint('Error saat upload/simpan: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan data: $e')),
                );
              }
            }

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
                    // --- PERBAIKAN: Menghapus 'crossAxisAlignment' yang duplikat ---
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Data Wisata' : 'Tambah Wisata Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(labelText: 'Nama Wisata', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: deskripsiController,
                        decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                        maxLines: 3,
                        validator: (val) => val!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hargaController,
                        decoration: const InputDecoration(labelText: 'Harga Tiket (cth: 25000 atau Gratis)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.text,
                        validator: (val) => val!.isEmpty ? 'Harga tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lokasiController,
                        decoration: const InputDecoration(labelText: 'Lokasi (Alamat / Link Google Maps)', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Lokasi tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      if (!isEdit) ...[
                        const Text('Gambar (Wajib, bisa lebih dari 1):'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                          onPressed: pickImages,
                        ),
                        if (newImages.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: newImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.file(newImages[index], width: 100, height: 100, fit: BoxFit.cover),
                                );
                              },
                            ),
                          ),
                      ],
                      if (isEdit)
                        const Text(
                          'Info: Edit gambar belum didukung. Silakan hapus dan buat ulang data jika ingin mengganti gambar.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kelola Tempat Wisata',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _buildWisataList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFormSheet(context);
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}