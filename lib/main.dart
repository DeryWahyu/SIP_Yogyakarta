// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Impor provider dan halaman-halaman
import 'provider/auth_provider.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';
import 'screen/dashboard_page.dart';

// --- BARU: Impor halaman admin ---
import 'screen/admin/kelola_wisata_page.dart';
import 'screen/admin/kelola_artikel_page.dart';
import 'screen/admin/kelola_pengguna_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(), // Halaman awal tetap Login
      routes: {
        // Rute yang sudah ada
        '/register': (ctx) => RegisterPage(),
        '/home': (ctx) => HomePage(),
        '/dashboard': (ctx) => DashboardPage(),
        
        // --- BARU: Tambahkan rute admin ---
        '/admin-wisata': (ctx) => KelolaWisataPage(),
        '/admin-artikel': (ctx) => KelolaArtikelPage(),
        '/admin-pengguna': (ctx) => KelolaPenggunaPage(),
      },
    );
  }
}