// lib/screen/admin/artikel_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtikelDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;

  const ArtikelDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final raw = doc.data();
    final Map<String, dynamic> data = raw is Map<String, dynamic> ? raw : {};

    final String judul = (data['judul'] as String?)?.trim() ?? 'Tanpa Judul';
    final String deskripsi = (data['deskripsi'] as String?)?.trim() ?? 'Tanpa Deskripsi';

    // Mendukung beberapa format field gambar: imageUrl (string), image (string), images (list)
    String? imageUrl;
    final dynamic imgField = data['imageUrl'] ?? data['image'] ?? data['images'];
    if (imgField is String && imgField.isNotEmpty) {
      imageUrl = imgField;
    } else if (imgField is List && imgField.isNotEmpty && imgField.first is String) {
      imageUrl = imgField.first as String;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(judul, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 250,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 250,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    deskripsi,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}