// lib/screen/admin/kelola_pengguna_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KelolaPenggunaPage extends StatefulWidget {
  const KelolaPenggunaPage({super.key});

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Data Pengguna',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      // Gunakan StreamBuilder untuk menampilkan data user secara real-time
      body: StreamBuilder<QuerySnapshot>(
        // Ambil data dari koleksi 'users' yang kita buat di langkah sebelumnya
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada pengguna terdaftar.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi error saat mengambil data.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              // Tampilkan data user
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['role'] == 'admin' ? 'A' : 'U'),
                ),
                title: Text(user['nama'] ?? 'Tanpa Nama'),
                subtitle: Text(user['email'] ?? 'Tanpa Email'),
                trailing: Text(
                  user['role'] ?? 'user',
                  style: TextStyle(
                    color: user['role'] == 'admin' ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}