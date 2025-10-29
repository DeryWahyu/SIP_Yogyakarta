// lib/screen/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'login_page.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

// --- IMPOR BARU ---
import '../widgets/wisata_count_chart.dart'; // Impor widget baru
import '../widgets/artikel_count_chart.dart'; // Impor widget baru
// --- AKHIR IMPOR BARU ---


// --- UBAH MENJADI STATEFULWIDGET ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> { // <-- Tambah State
  // --- STATE BARU ---
  final PageController _pageController = PageController(); // Controller untuk PageView
  int _currentPageIndex = 0; // Untuk melacak halaman aktif (dots indicator)
  // --- AKHIR STATE BARU ---


  // --- Daftar widget grafik ---
  final List<Widget> _chartWidgets = [
    const UserRolePieChart(),   // Grafik 1: Statistik Pengguna
    const WisataCountChart(), // Grafik 2: Jumlah Wisata
    const ArtikelCountChart(), // Grafik 3: Jumlah Artikel
  ];


  // --- Pindahkan _buildMenuListItem ke sini ---
    Widget _buildMenuListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String routeName,
  }) {
    // ... (Kode fungsi ini TIDAK BERUBAH) ...
     return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.of(context).pushNamed(routeName);
        },
      ),
    );
  }

  // --- Widget helper untuk dots indicator ---
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_chartWidgets.length, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPageIndex == index
                ? Theme.of(context).primaryColor // Warna dot aktif
                : Colors.grey.shade400,          // Warna dot tidak aktif
          ),
        );
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Ambil nama user dari Firestore (lebih akurat)
    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    String userName = 'Admin'; // Default name

    return Scaffold(
      appBar: AppBar(
        // --- Ambil nama dari Firestore ---
        title: StreamBuilder<DocumentSnapshot>(
          stream: currentUser != null 
              ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots() 
              : null, // Jangan stream jika user null
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              userName = userData['nama'] ?? 'Admin'; // Update nama
            }
            // Tampilkan UI AppBar setelah nama didapat (atau default)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang👋',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName, // Tampilkan nama dinamis
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }
        ),
        // --- Akhir pengambilan nama ---
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- BAGIAN GRAFIK (Diganti PageView) ---
          const Text(
            'Statistik Aplikasi', // Judul diubah
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // --- PAGEVIEW UNTUK GRAFIK ---
          SizedBox(
            height: 280, // Tinggi PageView (termasuk ruang untuk card)
            child: PageView.builder(
              controller: _pageController,
              itemCount: _chartWidgets.length,
              itemBuilder: (context, index) {
                // Beri padding agar card tidak mepet
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                  child: _chartWidgets[index],
                );
              },
              onPageChanged: (index) {
                // Update state saat halaman berganti
                setState(() {
                  _currentPageIndex = index;
                });
              },
            ),
          ),
          // --- DOTS INDICATOR ---
          _buildPageIndicator(),
          // --- AKHIR BAGIAN GRAFIK ---
          
          const SizedBox(height: 16), // Sesuaikan jarak

          // --- BAGIAN MENU ---
          const Text( // Pakai const jika bisa
            'Menu Manajemen',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Tombol-tombol menu (tidak berubah)
          _buildMenuListItem(
            context: context,
            icon: Icons.map_outlined,
            title: 'Kelola Wisata',
            subtitle: 'Tambah/Ubah data tempat wisata',
            color: Colors.green.shade700,
            routeName: '/admin-wisata',
          ),
          _buildMenuListItem(
            context: context,
            icon: Icons.article_outlined,
            title: 'Kelola Artikel',
            subtitle: 'Tambah/Ubah artikel & berita',
            color: Colors.orange.shade700,
            routeName: '/admin-artikel',
          ),
          _buildMenuListItem(
            context: context,
            icon: Icons.people_outline,
            title: 'Data Pengguna',
            subtitle: 'Lihat semua pengguna terdaftar',
            color: Colors.purple.shade700,
            routeName: '/admin-pengguna',
          ),
        ],
      ),
    );
  }

    // --- PASTI KAN FUNGSI INI ADA ---
   @override
   void dispose() {
     _pageController.dispose(); // Jangan lupa dispose controller
     super.dispose();
   }
}


// =========================================================================
// --- WIDGET UserRolePieChart (TIDAK BERUBAH) ---
// =========================================================================
class UserRolePieChart extends StatelessWidget {
  const UserRolePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Kode widget ini TIDAK BERUBAH, salin dari file lama Anda) ...
    // ATAU GUNAKAN KODE INI LAGI
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat data grafik'));
        }

        int adminCount = 0;
        int userCount = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'admin') {
            adminCount++;
          } else {
            userCount++;
          }
        }
        int totalUsers = adminCount + userCount;
        if (totalUsers == 0) {
           return const Center(child: Text('Belum ada pengguna terdaftar'));
        }

        return Card( // <-- Bungkus dengan Card di sini
           elevation: 4,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4, 
                      centerSpaceRadius: 40, 
                      sections: [
                        PieChartSectionData(
                          value: adminCount.toDouble(),
                          title: '$adminCount',
                          color: Colors.blue.shade700,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: userCount.toDouble(),
                          title: '$userCount',
                          color: Colors.green.shade600,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Users: $totalUsers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildLegendItem(Colors.blue.shade700, 'Admin'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.green.shade600, 'User'),
                    ],
                  ),
                ),
              ],
            ),
           ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    // ... (Kode helper ini tidak berubah) ...
     return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}