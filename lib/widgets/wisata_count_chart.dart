// lib/widgets/wisata_count_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WisataCountChart extends StatelessWidget {
  const WisataCountChart({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tempat_wisata').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error data wisata'));
        }

        int count = snapshot.data?.docs.length ?? 0;

        return Card(
          elevation: 6, // Sedikit lebih menonjol
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Sudut standar
          clipBehavior: Clip.antiAlias, // Penting agar gradient tidak keluar border
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient( // Gradient dari tengah ke luar
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.green.shade100, // Warna tengah (lebih terang)
                  Colors.green.shade50,  // Warna luar (hampir putih)
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Beri jarak merata
              children: [
                Icon(
                  Icons.map, // Ikon Peta
                  size: 55, // Ukuran ikon
                  color: Colors.green.shade800,
                ),
                Column( // Kelompokkan Angka dan Teks
                  children: [
                     Text(
                      '$count',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Destinasi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}