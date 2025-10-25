// lib/screen/admin/kelola_artikel_page.dart
import 'package:flutter/material.dart';

class KelolaArtikelPage extends StatefulWidget {
  const KelolaArtikelPage({super.key});

  @override
  State<KelolaArtikelPage> createState() => _KelolaArtikelPageState();
}

class _KelolaArtikelPageState extends State<KelolaArtikelPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Artikel'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: const Center(
        child: Text('Halaman untuk menambah/mengedit artikel'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Tampilkan dialog/bottom sheet untuk form tambah data
        },
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }
}