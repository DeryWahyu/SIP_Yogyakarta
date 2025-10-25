// lib/screen/admin/wisata_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WisataDetailPage extends StatelessWidget {
  // Kita akan mengirim data dokumen dari halaman sebelumnya
  final DocumentSnapshot doc;
  
  const WisataDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari dokumen
    final data = doc.data() as Map<String, dynamic>;
    final String nama = data['nama'] ?? 'Tanpa Nama';
    final String deskripsi = data['deskripsi'] ?? 'Tanpa Deskripsi';
    final String harga = data['harga'] ?? 'Gratis';
    final String lokasi = data['lokasi'] ?? 'Lokasi tidak diketahui';
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(nama, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GALERI GAMBAR (Bisa di-swipe) ---
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 250, // Atur tinggi galeri
                child: PageView.builder( // PageView untuk galeri swipe
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.contain,
                          // Tampilkan loading indicator saat gambar dimuat
                          loadingBuilder: (context, child, progress) {
                            return progress == null 
                                ? child 
                                : const Center(child: CircularProgressIndicator());
                          },
                          // Tampilkan error jika gambar gagal dimuat
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              // Tampilan jika tidak ada gambar
              Container(
                height: 250,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),

            // --- DETAIL TEKS ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.description, 'Deskripsi', deskripsi),
                  _buildDetailRow(Icons.monetization_on, 'Harga', harga),
                  _buildDetailRow(Icons.location_on, 'Lokasi', lokasi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk membuat baris detail (Icon, Judul, Isi)
  Widget _buildDetailRow(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}