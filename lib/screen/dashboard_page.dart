// lib/screen/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'login_page.dart';

// --- IMPOR BARU ---
import 'package:fl_chart/fl_chart.dart'; // Untuk grafik
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk ambil data users

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
      title: Column(
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
        const Text(
          'Dery Wahyu Perdana',
          style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          ),
        ),
        ],
      ),
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
      // --- UI BARU: Menggunakan ListView ---
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- BAGIAN GRAFIK ---
          const Text(
            'Statistik Pengguna',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Widget Card untuk membungkus grafik
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 250, // Beri ketinggian pada area grafik
              child: UserRolePieChart(), // Panggil widget grafik kita
            ),
          ),
          
          const SizedBox(height: 24),

          // --- BAGIAN MENU ---
          Text(
            'Menu Manajemen',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Tombol 1: Kelola Tempat Wisata (UI Baru)
          _buildMenuListItem(
            context: context,
            icon: Icons.map_outlined,
            title: 'Kelola Wisata',
            subtitle: 'Tambah/Ubah data tempat wisata',
            color: Colors.green.shade700,
            routeName: '/admin-wisata',
          ),
          
          // Tombol 2: Kelola Artikel (UI Baru)
          _buildMenuListItem(
            context: context,
            icon: Icons.article_outlined,
            title: 'Kelola Artikel',
            subtitle: 'Tambah/Ubah artikel & berita',
            color: Colors.orange.shade700,
            routeName: '/admin-artikel',
          ),

          // Tombol 3: Kelola Pengguna (UI Baru)
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

  // --- WIDGET HELPER BARU: untuk menu ---
  Widget _buildMenuListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String routeName,
  }) {
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
}


// =========================================================================
// --- WIDGET BARU UNTUK GRAFIK PIE CHART ---
// =========================================================================

class UserRolePieChart extends StatelessWidget {
  const UserRolePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan StreamBuilder untuk mengambil data dari koleksi 'users'
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        // Tampilkan loading jika data belum siap
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Tampilkan error jika ada masalah
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat data grafik'));
        }

        // --- Proses Data ---
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

        // --- Tampilkan Grafik ---
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // --- PIE CHART ---
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4, // Jarak antar bagian
                    centerSpaceRadius: 40, // Lubang di tengah
                    sections: [
                      // Data untuk Admin
                      PieChartSectionData(
                        value: adminCount.toDouble(),
                        title: '$adminCount',
                        color: Colors.blue.shade700,
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      // Data untuk User
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
              
              // --- LEGENDA (Keterangan) ---
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: $totalUsers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildLegendItem(Colors.blue.shade700, 'Admin'),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green.shade600, 'User'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget helper untuk legenda
  Widget _buildLegendItem(Color color, String text) {
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