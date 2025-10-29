// lib/screen/user/home_tab.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_wisata_detail_page.dart'; 
import '../admin/artikel_detail_page.dart'; 

class HomeTab extends StatelessWidget {
  final Function(int) onNavTapped;
  const HomeTab({super.key, required this.onNavTapped});

  final List<String> headerImages = const [
    'assets/images/header1.jpg',
    'assets/images/header2.jpg',
    'assets/images/header3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    // Membungkus SingleChildScrollView dengan Container berwarna putih
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: _buildHeaderCarousel(),
            ),
            _buildSearchBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Rekomendasi Wisata',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            _buildWisataList(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Artikel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            _buildArtikelList(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCarousel() {
    return CarouselSlider.builder(
      itemCount: headerImages.length,
      itemBuilder: (context, index, realIndex) {
        return Image.asset(
          headerImages[index],
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
      options: CarouselOptions(
        height: 250,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 1.0, 
        enlargeCenterPage: false,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
      child: GestureDetector(
        onTap: () {
          onNavTapped(1); 
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AbsorbPointer(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Cari Tempat Wisata Favoritmu',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWisataList(BuildContext context) {
    return SizedBox(
      height: 220, 
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tempat_wisata').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data wisata.'));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              var imageUrls = data['imageUrls'] as List?;
              String imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
                  ? imageUrls[0]
                  : ''; 

              return _buildWisataCard(
                context,
                title: data['nama'] ?? 'Tanpa Judul',
                description: data['deskripsi'] ?? 'Tanpa Deskripsi',
                imageUrl: imageUrl,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => UserWisataDetailPage(doc: doc, onNavTapped: onNavTapped),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArtikelList(BuildContext context) {
    return SizedBox(
      height: 160, 
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('artikel').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data artikel.'));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String imageUrl = data['imageUrl'] ?? '';

              return _buildArtikelCard(
                context,
                title: data['judul'] ?? 'Tanpa Judul',
                description: data['deskripsi'] ?? 'Tanpa Deskripsi',
                imageUrl: imageUrl,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ArtikelDetailPage(doc: doc),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildWisataCard(BuildContext context, {required String title, required String description, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
                errorBuilder: (ctx, err, stack) => Container(height: 120, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
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

  Widget _buildArtikelCard(BuildContext context, {required String title, required String description, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250, 
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.network(
                imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/100',
                height: double.infinity,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(width: 100, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
