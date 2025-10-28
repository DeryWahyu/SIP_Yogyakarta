// lib/screen/home_page.dart

import 'package:flutter/material.dart';
import 'user/home_tab.dart';
import 'user/search_tab.dart';
import 'user/favorite_tab.dart';
import 'user/profile_tab.dart';
// --- IMPOR BARU ---
import 'package:sistem_informasi_tempat_wisata/widgets/custom_bottom_nav_bar.dart'; 
// (Sesuaikan 'sistem_informasi_tempat_wisata' dengan nama paket Anda jika beda)
// --- AKHIR IMPOR BARU ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  late final List<Widget> _widgetOptions; 
  @override
  void initState() {
    super.initState();
    // Kita panggil _onItemTapped DARI SINI
    _widgetOptions = <Widget>[
      HomeTab(onNavTapped: _onItemTapped),
      SearchTab(), 
      FavoriteTab(), // Kita tidak perlu onNavTapped di sini lagi
      ProfileTab(), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- BARU: Buat daftar AppBar untuk setiap tab ---
  static final List<PreferredSizeWidget?> _appBarOptions = <PreferredSizeWidget?>[
    null, // Tab 0 (HomeTab) tidak punya AppBar
    null, // Tab 1 (SearchTab) tidak punya AppBar
    // Tab 2 (FavoriteTab) punya AppBar
    PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        title: Text('Wisata Favorit Saya'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
    ),
    // Tab 3 (ProfileTab) punya AppBar
    PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        title: Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
    ),
  ];
  // --- AKHIR BARU ---


  @override
  Widget build(BuildContext context) {
    // --- GANTI TOTAL ---
    // Kita gunakan DefaultTabController agar bisa memanggil 
    // _onItemTapped dari dalam FavoriteTab
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) {
          // Kita tambahkan listener agar bisa dipanggil dari FavoriteTab
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              _onItemTapped(tabController.index);
            }
          });

          return Scaffold(
            // Tampilkan AppBar yang sesuai
            appBar: _appBarOptions[_selectedIndex],
            // Tampilkan Body yang sesuai
            body: _widgetOptions[_selectedIndex],
            // Tampilkan Navbar Kustom
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ), 
          );
        }
      ),
    );
    // --- AKHIR GANTI TOTAL ---
  }
}