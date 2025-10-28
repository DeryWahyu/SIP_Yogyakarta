// lib/screen/admin/wisata_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WisataDetailPage extends StatefulWidget {
  final DocumentSnapshot doc;
  
  const WisataDetailPage({Key? key, required this.doc}) : super(key: key);

  @override
  State<WisataDetailPage> createState() => _WisataDetailPageState();
}

class _WisataDetailPageState extends State<WisataDetailPage> {

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    
    // --- FIX 1: Ini adalah URL yang BENAR untuk rute ---
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(googleMapsUrl);

    // Cek apakah bisa membuka URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      
      // --- FIX 2: Cek 'mounted' untuk mengatasi peringatan async gap ---
      // Ini memastikan widget masih ada di layar sebelum menampilkan SnackBar
      if (!context.mounted) return; 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps. Pastikan sudah ter-install.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari dokumen
    final data = widget.doc.data() as Map<String, dynamic>;
    final String nama = data['nama'] ?? 'Tanpa Nama';
    final String deskripsi = data['deskripsi'] ?? 'Tanpa Deskripsi';
    final String harga = data['harga'] ?? 'Gratis';
    
    // Ambil data lokasi baru
    final String lokasiAlamat = data['lokasi'] ?? 'Lokasi tidak diketahui';
    final double latitude = data['latitude'] ?? 0.0;
    final double longitude = data['longitude'] ?? 0.0;

    // --- TAMBAHAN BARU ---
    final String hariBuka = data['hariBuka'] ?? 'Informasi tidak tersedia';
    final String jamOperasional = data['jamOperasional'] ?? 'Informasi tidak tersedia';
    // --- AKHIR TAMBAHAN ---

    final List<dynamic> imageUrls = data['imageUrls'] ?? [];
    
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        // ... (AppBar TIDAK BERUBAH) ...
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        backgroundColor: Colors.transparent, 
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- GALERI GAMBAR (Header) ---
            if (imageUrls.isNotEmpty)
              SizedBox(
                // ... (Widget Galeri Gambar TIDAK BERUBAH) ...
                height: 300, 
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover, 
                        loadingBuilder: (context, child, progress) {
                          return progress == null 
                              ? child 
                              : const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                        },
                      ),
                    );
                  },
                ),
              )
            else
              // ... (Placeholder Gambar TIDAK BERUBAH) ...
              Container(
                height: 300,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
              ),

            // --- JUDUL ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                nama, 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ),

            // --- DETAIL TEKS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Deskripsi'),
                  Text(deskripsi, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5), textAlign: TextAlign.justify,),
                  
                  const SizedBox(height: 16),
                  _buildSectionTitle('Harga Tiket'),
                  Text('Rp. ${harga}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  
                  // --- TAMBAHAN BARU ---
                  const SizedBox(height: 16),
                  _buildSectionTitle('Hari & Jam Operasional'),
                  _buildInfoRow(Icons.calendar_today_outlined, hariBuka),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time_outlined, jamOperasional),
                  // --- AKHIR TAMBAHAN ---

                  const SizedBox(height: 16),
                  _buildSectionTitle('Lokasi'),
                  Text(lokasiAlamat, style: const TextStyle(fontSize: 14)),
                  
                  const SizedBox(height: 20),

                  // --- TOMBOL LIHAT RUTE (TIDAK BERUBAH) ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Lihat rute di Google Maps'),
                      onPressed: () {
                        if (latitude != 0.0 && longitude != 0.0) {
                          _launchGoogleMaps(latitude, longitude);
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Koordinat lokasi tidak tersedia untuk rute.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Jarak di bawah
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // --- HELPER BARU ---
  // Widget helper untuk baris info (Ikon + Teks)
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
  // --- AKHIR HELPER BARU ---
}