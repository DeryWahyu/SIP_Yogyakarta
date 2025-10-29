// lib/widgets/artikel_count_chart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Pastikan fl_chart sudah diimpor

class ArtikelCountChart extends StatelessWidget {
  const ArtikelCountChart({super.key});

  // Tentukan target maksimum untuk gauge chart
  final double maxTarget = 50.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('artikel').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error data artikel'));
        }

        int count = snapshot.data?.docs.length ?? 0;
        double currentPercentage = (count / maxTarget) * 100;
        // Batasi persentase maksimal 100%
        if (currentPercentage > 100) currentPercentage = 100;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Container(
             decoration: BoxDecoration(
              gradient: RadialGradient( // Gradient halus
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.orange.shade100,
                  Colors.orange.shade50,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- GAUGE CHART ---
                SizedBox(
                  height: 150, // Tinggi area chart
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90, // Mulai dari atas
                          sectionsSpace: 0, // Tidak ada jarak antar bagian
                          centerSpaceRadius: 50, // Lubang tengah
                          sections: [
                            // Bagian yang sudah terisi (progress)
                            PieChartSectionData(
                              value: currentPercentage,
                              color: Colors.orange.shade600,
                              radius: 15, // Ketebalan bar
                              showTitle: false, // Jangan tampilkan angka di bar
                            ),
                            // Bagian sisa (latar belakang)
                            PieChartSectionData(
                              value: 100 - currentPercentage,
                              color: Colors.grey.shade300,
                              radius: 15,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      // Teks Angka di Tengah
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text(
                            '$count',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                          ),
                           Text(
                             'Artikel',
                             style: TextStyle(color: Colors.grey.shade600),
                           )
                        ],
                      )
                    ],
                  ),
                ),
                 // --- AKHIR GAUGE CHART ---
                const SizedBox(height: 10),
                Text(
                  'Publikasi Konten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}