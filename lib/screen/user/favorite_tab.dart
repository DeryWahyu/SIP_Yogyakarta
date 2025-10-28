// lib/screen/user/favorite_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_wisata_detail_page.dart'; 
// Hapus impor navbar, karena tidak dipakai di sini lagi
// import '../../widgets/custom_bottom_nav_bar.dart'; 

class FavoriteTab extends StatefulWidget {
  // --- HAPUS INI ---
  // final Function(int) onNavTapped;
  // const FavoriteTab({super.key, required this.onNavTapped});
  // --- GANTI DENGAN INI ---
  const FavoriteTab({super.key});
  // --- AKHIR PERUBAHAN ---

  @override
  State<FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // --- TAMBAHKAN FUNGSI INI ---
  // Kita perlu meneruskan fungsi onNavTapped ke detail page
  // Kita ambil dari 'context' (cara yang sedikit canggih)
  void _onNavTapped(int index) {
    // Ini akan memanggil animateTo pada DefaultTabController jika ada
    DefaultTabController.of(context).animateTo(index);
  }
  // --- AKHIR TAMBAHAN ---


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
            // --- PERUBAHAN DI SINI ---
            builder: (ctx) => UserWisataDetailPage(doc: doc, onNavTapped: _onNavTapped),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Anda harus login untuk melihat favorit.'));
    }

    return StreamBuilder<DocumentSnapshot>(
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

        if (favoriteIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Anda belum memiliki wisata favorit.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text('Tekan ikon Hati pada wisata untuk menambahkannya.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tempat_wisata')
              .where(FieldPath.documentId, whereIn: favoriteIds)
              .snapshots(),
          builder: (context, wisataSnapshot) {
            if (wisataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!wisataSnapshot.hasData || wisataSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Data favorit tidak ditemukan.'));
            }

            final wisataDocs = wisataSnapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.75, 
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: wisataDocs.length,
              itemBuilder: (context, index) {
                return _buildWisataCard(context, doc: wisataDocs[index]);
              },
            );
          },
        );
      },
    );
  }
}
