// lib/screen/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'login_page.dart'; // Impor login page untuk navigasi saat logout

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              // Arahkan kembali ke login dan hapus semua riwayat navigasi
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Selamat datang, Anda berhasil login!'),
      ),
    );
  }
}