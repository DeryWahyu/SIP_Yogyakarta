// lib/screen/user/user_wisata_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:carousel_slider/carousel_slider.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
// --- IMPOR BARU ---
import '../../widgets/custom_bottom_nav_bar.dart'; // Impor custom navbar
// --- AKHIR IMPOR BARU ---

class UserWisataDetailPage extends StatefulWidget {
  final DocumentSnapshot doc;
  final Function(int) onNavTapped; 
  
  const UserWisataDetailPage({
    Key? key, 
    required this.doc, 
    required this.onNavTapped, 
  }) : super(key: key);

  @override
  State<UserWisataDetailPage> createState() => _UserWisataDetailPageState();
}

class _UserWisataDetailPageState extends State<UserWisataDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  bool _isFavorited = false;
  bool _isLoadingFavorite = true; 
  int _currentImageIndex = 0; 

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  // ... (Fungsi _checkIfFavorited, _toggleFavorite, _launchGoogleMaps tidak berubah) ...
  Future<void> _checkIfFavorited() async {
    if (_userId == null) {
      setState(() => _isLoadingFavorite = false);
      return; 
    }
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        final List<dynamic> favorites = userDoc.data()?['favorites'] ?? [];
        setState(() {
          _isFavorited = favorites.contains(widget.doc.id);
          _isLoadingFavorite = false;
        });
      } else {
        setState(() => _isLoadingFavorite = false);
      }
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
      debugPrint("Error cek favorit: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menambah favorit.'))
      );
      return;
    }

    setState(() {
      _isFavorited = !_isFavorited;
    });

    final docRef = _firestore.collection('users').doc(_userId);
    final String wisataId = widget.doc.id;

    try {
      if (_isFavorited) {
        await docRef.update({
          'favorites': FieldValue.arrayUnion([wisataId])
        });
      } else {
        await docRef.update({
          'favorites': FieldValue.arrayRemove([wisataId])
        });
      }
    } catch (e) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan favorit: $e'))
      );
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final String googleMapsUrl = 'http://googleusercontent.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Pengambilan data tidak berubah) ...
    final data = widget.doc.data() as Map<String, dynamic>;
    final String nama = data['nama'] ?? 'Tanpa Nama';
    final String deskripsi = data['deskripsi'] ?? 'Tanpa Deskripsi';
    final String harga = data['harga'] ?? 'Gratis';
    final String lokasiAlamat = data['lokasi'] ?? '...';
    final double latitude = data['latitude'] ?? 0.0;
    final double longitude = data['longitude'] ?? 0.0;
    final String hariBuka = data['hariBuka'] ?? '...';
    final String jamOperasional = data['jamOperasional'] ?? '...';
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white, // --> Background diubah menjadi putih
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isLoadingFavorite
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.green : Colors.black, 
                  ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0), 
              child: Text(
                nama,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, 
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (imageUrls.isNotEmpty)
              Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index, realIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20), 
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 250,
                      autoPlay: imageUrls.length > 1, 
                      viewportFraction: 1.0, 
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: imageUrls.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black)
                                .withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Deskripsi'),
                  Text(deskripsi, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5), textAlign: TextAlign.justify,),
                  
                  const SizedBox(height: 16),
                    Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -4),
                        child: const Icon(Icons.confirmation_num, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      _buildSectionTitle('Harga Tiket'),
                    ],
                    ),
                  Transform.translate(
                    offset: const Offset( 35, 0),
                    child: Text('Rp. ${harga}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                  ),
                  
                  const SizedBox(height: 16),
                    Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.schedule_sharp, color: Colors.black87, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Hari & Jam Operasional',
                        style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        ),
                      ),
                      ],
                    ),
                    ),
                    Padding(
                    padding: const EdgeInsets.only(left: 35.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      _buildInfoRow(Icons.calendar_today_outlined, hariBuka),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time_outlined, jamOperasional),
                      ],
                    ),
                    ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -4),
                        child: const Icon(Icons.location_on, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      _buildSectionTitle('Lokasi'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 35.0),
                    child: Text(lokasiAlamat, style: const TextStyle(fontSize: 14)),
                  ),
                  
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (latitude != 0.0 && longitude != 0.0) {
                          _launchGoogleMaps(latitude, longitude);
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Koordinat lokasi tidak tersedia.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Lihat Rute di Google Maps'),
                    ),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
      
      // --- PANGGIL CUSTOM NAVBAR YANG BARU ---
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, // Di detail, kita anggap tetap di tab "Home"
        onItemTapped: (index) {
          // Ketika item navbar ditekan di halaman detail
          // kita pop dulu halaman detail ini
          Navigator.of(context).pop();
          // Lalu kita panggil fungsi onNavTapped dari HomePage untuk ganti tab
          widget.onNavTapped(index);
        },
      ),
    );
  }

  // ... (_buildSectionTitle dan _buildInfoRow tidak berubah) ...
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

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
}