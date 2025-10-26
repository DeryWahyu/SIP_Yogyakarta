// lib/screen/home_page.dart
import 'package:flutter/material.dart';
import 'user/home_tab.dart';
import 'user/search_tab.dart';
import 'user/favorite_tab.dart';
import 'user/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Indeks tab yang sedang aktif

  // Daftar halaman/tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    SearchTab(),
    FavoriteTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan tab yang dipilih
      body: IndexedStack( // IndexedStack menjaga state setiap tab
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // --- BOTTOM NAVIGATION BAR (Sesuai Desain) ---
      // Kita bungkus dengan Stack agar bisa "mengambang"
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    // Tampilan bottom nav bar kustom
    return Container(
      // Kita beri padding agar "mengambang"
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      // Kita pakai Stack agar bisa menempatkan bar di atas konten
      child: Container(
        height: 70, // Tinggi bar
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35), // Bentuk pil
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.search, 'Search', 1),
            _buildNavItem(Icons.favorite, 'Favorite', 2),
            _buildNavItem(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk setiap ikon di nav bar
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? Colors.green.shade700 : Colors.grey.shade400;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}