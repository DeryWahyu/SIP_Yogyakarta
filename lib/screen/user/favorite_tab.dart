// lib/screen/user/favorite_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_wisata_detail_page.dart';

class FavoriteTab extends StatefulWidget {
  const FavoriteTab({super.key});

  @override
  State<FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  void _onNavTapped(int index) {
    // Pastikan widget masih ada sebelum memanggil DefaultTabController
    if (mounted) {
      try {
        DefaultTabController.of(context).animateTo(index);
      } catch (e) {
        debugPrint("Error navigating from FavoriteTab: $e");
        // Fallback jika controller tidak ditemukan (seharusnya tidak terjadi)
      }
    }
  }


  // --- MODIFIKASI: _buildWisataCard ---
  Widget _buildWisataCard(BuildContext context, {required DocumentSnapshot doc}) {
    var data = doc.data() as Map<String, dynamic>;
    var imageUrls = data['imageUrls'] as List?;
    String imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls[0]
        : '';
    String title = data['nama'] ?? 'Tanpa Judul';
    String description = data['deskripsi'] ?? 'Tanpa Deskripsi';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => UserWisataDetailPage(doc: doc, onNavTapped: _onNavTapped),
          ),
        );
      },
      child: Container(
        // --- TAMBAHAN: Gunakan Stack untuk menumpuk ikon hati ---
        child: Stack(
          children: [
            // Konten kartu yang sudah ada
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            constraints: const BoxConstraints(minHeight: 220), // Perlebar kebawah
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: Offset(0, 4),
              ),
            ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
                height: 120, // Tinggi gambar diperbesar
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                height: 150,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
              ),
              Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2, // Biarkan 2 baris untuk judul
                overflow: TextOverflow.ellipsis,
              ),
              ),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 2, // Tambah baris deskripsi agar tidak tumpuk
                overflow: TextOverflow.ellipsis,
              ),
              ),
              const SizedBox(height: 8), // Ruang tambahan di bawah
            ],
            ),
          ),
              ],
            ),
            // --- TAMBAHAN: Ikon Hati di Pojok Kanan Atas ---
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8), // Background semi-transparan
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.green.shade700, // Warna hati hijau
                  size: 18, // Ukuran ikon kecil
                ),
              ),
            ),
            // --- AKHIR TAMBAHAN ---
          ],
        ),
        // --- AKHIR Stack ---
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Anda harus login untuk melihat favorit.'));
    }

    return Container(
      color: Colors.white,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(_userId).snapshots(),
        builder: (context, userSnapshot) {
           if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Gagal memuat data user.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> favoriteIds = userData['favorites'] ?? [];

          // --- TAMPILAN EMPTY STATE YANG DIPERBAIKI ---
          if (favoriteIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Beri padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_outline, size: 100, color: Colors.grey.shade300), // Ikon lebih besar & halus
                    const SizedBox(height: 24),
                    Text(
                      'Belum Ada Favorit',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Tekan ikon Hati 💚 pada detail wisata untuk menambahkannya ke sini.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          // --- AKHIR EMPTY STATE ---

          // --- AMBIL JUMLAH FAVORIT ---
          final int favoriteCount = favoriteIds.length;

          // --- BANGUN UI UTAMA (Jumlah + Grid) ---
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TAMBAHAN: Tampilkan Jumlah Favorit ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Anda memiliki $favoriteCount Wisata Favorit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green.shade800),
                ),
              ),
              // --- AKHIR TAMBAHAN ---

              // --- Grid Hasil (dibungkus Expanded) ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('tempat_wisata')
                      .where(FieldPath.documentId, whereIn: favoriteIds)
                      .snapshots(),
                  builder: (context, wisataSnapshot) {
                    if (wisataSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!wisataSnapshot.hasData || wisataSnapshot.data!.docs.isEmpty) {
                      // Ini seharusnya tidak terjadi jika favoriteIds tidak kosong,
                      // tapi tambahkan fallback untuk jaga-jaga
                      return const Center(child: Text('Data favorit tidak ditemukan atau telah dihapus.'));
                    }

                    final wisataDocs = wisataSnapshot.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8, // Rasio sebelumnya
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: wisataDocs.length,
                      itemBuilder: (context, index) {
                        return _buildWisataCard(context, doc: wisataDocs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
          // --- AKHIR UI UTAMA ---
        },
      ),
    );
  }
}