// lib/screen/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      // Gunakan GridView untuk tampilan menu yang lebih baik
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2, // 2 kolom
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          // Tombol 1: Kelola Tempat Wisata
          _buildMenuCard(
            context: context,
            icon: Icons.map_outlined,
            title: 'Kelola Wisata',
            subtitle: 'Tambah/Ubah data wisata',
            color: Colors.green.shade700,
            routeName: '/admin-wisata',
          ),
          
          // Tombol 2: Kelola Artikel
          _buildMenuCard(
            context: context,
            icon: Icons.article_outlined,
            title: 'Kelola Artikel',
            subtitle: 'Tambah/Ubah artikel',
            color: Colors.orange.shade700,
            routeName: '/admin-artikel',
          ),

          // Tombol 3: Kelola Pengguna
          _buildMenuCard(
            context: context,
            icon: Icons.people_outline,
            title: 'Data Pengguna',
            subtitle: 'Lihat data pengguna terdaftar',
            color: Colors.purple.shade700,
            routeName: '/admin-pengguna',
          ),
          
          // Anda bisa tambahkan menu lain di sini
        ],
      ),
    );
  }

  // Widget helper untuk membuat kartu menu
  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String routeName,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigasi ke halaman yang sesuai
          Navigator.of(context).pushNamed(routeName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40.0, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}