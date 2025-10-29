// lib/screen/user/search_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_wisata_detail_page.dart'; // Untuk navigasi ke detail wisata
import '../admin/artikel_detail_page.dart'; // Untuk navigasi ke detail artikel

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  // Firestore instance untuk query
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Tempat Wisata'; // Default filter
  String _searchQuery = ''; // Query pencarian saat ini

  // Fungsi untuk menjalankan pencarian
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim(); // Simpan query & hapus spasi awal/akhir
    });
  }

  // Fungsi untuk mendapatkan fungsi navigasi berdasarkan filter
  Function(DocumentSnapshot) _getNavigationFunction() {
    if (_selectedFilter == 'Tempat Wisata') {
      return (doc) {
        // Navigasi ke detail wisata user
        Navigator.of(context).push(
          MaterialPageRoute(
            // Kita perlu ambil onNavTapped dari HomePage, cara mudahnya pakai DefaultTabController
            builder: (ctx) => UserWisataDetailPage(doc: doc, onNavTapped: (index) {
              DefaultTabController.of(context).animateTo(index);
            }),
          ),
        );
      };
    } else { // Artikel
      return (doc) {
        // Navigasi ke detail artikel (masih pakai versi admin)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ArtikelDetailPage(doc: doc),
          ),
        );
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Hapus bayangan
        title: _buildSearchBar(), // Panggil search bar di AppBar
        titleSpacing: 0, // Hapus spasi default title
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FILTER (Tempat Wisata / Artikel) ---
          _buildFilterChips(),

          const Divider(height: 1), // Garis pemisah

          // --- HASIL PENCARIAN ---
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // --- WIDGET UNTUK SETIAP BAGIAN ---

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0), // Beri jarak kiri & kanan
      height: 45, // Tinggi search bar
      decoration: BoxDecoration(
        color: Colors.white, // Background putih
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 6,
        offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Cari...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 12.0), // Atur padding vertikal
        ),
        onChanged: _performSearch, // Langsung cari saat teks berubah
        // Atau bisa pakai onSubmitted jika ingin cari saat enter ditekan
        // onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tempat Wisata'),
            selected: _selectedFilter == 'Tempat Wisata',
            onSelected: (selected) {
              if (selected) {
                setState(() { _selectedFilter = 'Tempat Wisata'; });
                // Ulangi pencarian dengan filter baru jika ada query
                if (_searchQuery.isNotEmpty) _performSearch(_searchQuery);
              }
            },
            selectedColor: Colors.green.shade100,
            checkmarkColor: Colors.green.shade800,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Artikel'),
            selected: _selectedFilter == 'Artikel',
            onSelected: (selected) {
              if (selected) {
                setState(() { _selectedFilter = 'Artikel'; });
                 if (_searchQuery.isNotEmpty) _performSearch(_searchQuery);
              }
            },
            selectedColor: Colors.green.shade100,
            checkmarkColor: Colors.green.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Jika query kosong, tampilkan pesan default
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Masukkan kata kunci pencarian', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Tentukan koleksi dan field berdasarkan filter
    String collectionPath = _selectedFilter == 'Tempat Wisata' ? 'tempat_wisata' : 'artikel';
    String fieldToSearch = _selectedFilter == 'Tempat Wisata' ? 'nama' : 'judul';

    return StreamBuilder<QuerySnapshot>(
      // Query ke Firestore
      stream: _firestore
          .collection(collectionPath)
          // --- LOGIKA PENCARIAN SEDERHANA ---
          // Cari field yang >= query dan < query + karakter terakhir + 1
          // Ini trik untuk simulasi 'startsWith' di Firestore
          .where(fieldToSearch, isGreaterThanOrEqualTo: _searchQuery)
          .where(fieldToSearch, isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          // --- BATAS LOGIKA PENCARIAN ---
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error saat mencari data.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.search_off, size: 50, color: Colors.grey),
                 SizedBox(height: 8),
                 Text('Hasil Pencarian Tidak Ditemukan', style: TextStyle(color: Colors.grey)),
               ],
             ),
          );
        }

        final results = snapshot.data!.docs;
        final navigate = _getNavigationFunction(); // Dapatkan fungsi navigasi

        // Tampilkan hasil dalam ListView
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>;
            
            // Ambil data untuk tampilan list (mirip desain Anda)
            String title = data[fieldToSearch] ?? 'Tanpa Judul/Nama';
            String subtitle = '';
            String imageUrl = '';

            if (_selectedFilter == 'Tempat Wisata') {
              subtitle = data['lokasi'] ?? ''; // Tampilkan alamat singkat
              var imageUrls = data['imageUrls'] as List?;
              imageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : '';
            } else { // Artikel
              subtitle = data['deskripsi'] ?? ''; // Tampilkan deskripsi singkat
              imageUrl = data['imageUrl'] ?? '';
            }
            return ListTile(
              leading: imageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                    )
                  : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
              title: Text(title),
              subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => navigate(doc), // Panggil fungsi navigasi
            );
          },
        );
      },
    );
  }
}