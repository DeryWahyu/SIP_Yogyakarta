// lib/screen/admin/kelola_wisata_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'wisata_detail_page.dart'; 

class KelolaWisataPage extends StatefulWidget {
  const KelolaWisataPage({super.key});

  @override
  State<KelolaWisataPage> createState() => _KelolaWisataPageState();
}

class _KelolaWisataPageState extends State<KelolaWisataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Widget _buildWisataList() {
    // ... (Fungsi ini TIDAK BERUBAH) ...
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => WisataDetailPage(doc: doc),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
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
    // ... (Fungsi ini TIDAK BERUBAH) ...
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
    final lokasiAlamatController = TextEditingController(); 
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    
    // --- TAMBAHAN BARU ---
    final hariBukaController = TextEditingController();
    final jamOperasionalController = TextEditingController();
    // --- AKHIR TAMBAHAN ---

    List<File> newImages = []; 
    bool isLoading = false;

    if (isEdit) {
      final data = existingData.data() as Map<String, dynamic>;
      namaController.text = data['nama'] ?? '';
      deskripsiController.text = data['deskripsi'] ?? '';
      hargaController.text = data['harga'] ?? '';
      lokasiAlamatController.text = data['lokasi'] ?? ''; 
      latitudeController.text = (data['latitude'] ?? 0.0).toString();
      longitudeController.text = (data['longitude'] ?? 0.0).toString();
      
      // --- TAMBAHAN BARU ---
      hariBukaController.text = data['hariBuka'] ?? '';
      jamOperasionalController.text = data['jamOperasional'] ?? '';
      // --- AKHIR TAMBAHAN ---
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            Future<void> pickImages() async {
              // ... (Fungsi _pickImages TIDAK BERUBAH) ...
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
                return;
              }

              setStateModal(() => isLoading = true);

              final cloudinary = CloudinaryPublic(
                'do1f1njjy', // GANTI JIKA BEDA
                'axgi2x1n', // GANTI JIKA BEDA
                cache: false,
              );

              try {
                final double latitude = double.tryParse(latitudeController.text) ?? 0.0;
                final double longitude = double.tryParse(longitudeController.text) ?? 0.0;

                Map<String, dynamic> dataToSave = {
                  'nama': namaController.text,
                  'deskripsi': deskripsiController.text,
                  'harga': hargaController.text,
                  'lokasi': lokasiAlamatController.text,
                  'latitude': latitude,
                  'longitude': longitude,
                  
                  // --- TAMBAHAN BARU ---
                  'hariBuka': hariBukaController.text,
                  'jamOperasional': jamOperasionalController.text,
                  // --- AKHIR TAMBAHAN ---
                };

                if (!isEdit) {
                  // ... (Logika upload gambar TIDAK BERUBAH) ...
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
                        decoration: const InputDecoration(labelText: 'Harga Tiket (cth: 50000)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Harga tidak boleh kosong' : null,
                      ),
                      
                      // --- TAMBAHAN BARU ---
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hariBukaController,
                        decoration: const InputDecoration(labelText: 'Hari Buka (cth: Senin - Minggu)', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Hari buka tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jamOperasionalController,
                        decoration: const InputDecoration(labelText: 'Jam Operasional (cth: 08:00 - 17:00)', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Jam operasional tidak boleh kosong' : null,
                      ),
                      // --- AKHIR TAMBAHAN ---
                      
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lokasiAlamatController,
                        decoration: const InputDecoration(labelText: 'Alamat Singkat (cth: Yogyakarta)', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Alamat singkat tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latitudeController,
                              decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: longitudeController,
                              decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Klik kanan di Google Maps untuk copy Latitude & Longitude.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (!isEdit) ...[
                        // ... (Kode pilih gambar TIDAK BERUBAH) ...
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

  @override
  Widget build(BuildContext context) {
    // ... (Fungsi build() TIDAK BERUBAH selain warna yang diminta) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tempat Wisata', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // tombol kembali jadi putih
      ),
      body: _buildWisataList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFormSheet(context);
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white), // ikon + jadi putih
      ),
    );
  }
}