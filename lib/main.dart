// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <-- Provider tetap dibutuhkan untuk Auth
import 'firebase_options.dart';

// Impor provider
import 'provider/auth_provider.dart';
// import 'provider/theme_provider.dart'; // <-- HAPUS IMPOR INI

// Impor halaman-halaman
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';
import 'screen/dashboard_page.dart';
import 'screen/admin/kelola_wisata_page.dart';
import 'screen/admin/kelola_artikel_page.dart';
import 'screen/admin/kelola_pengguna_page.dart';
import 'screen/user/edit_profile_page.dart'; // <-- TAMBAHKAN IMPOR INI


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // --- KEMBALIKAN KE ChangeNotifierProvider BIASA ---
    ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: const MyApp(),
    ),
    // --- AKHIR PERUBAHAN ---
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- HAPUS PANGGILAN themeProvider ---
    // final themeProvider = Provider.of<ThemeProvider>(context);
    // --- AKHIR PENGHAPUSAN ---

    return MaterialApp(
      title: 'Info Wisata',
      // --- KEMBALIKAN PENGATURAN TEMA DEFAULT ---
      themeMode: ThemeMode.system, // Atau ThemeMode.light
      theme: ThemeData( // Tema terang (default)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme( // Konsistensi AppBar terang
           backgroundColor: Colors.white,
           foregroundColor: Colors.black, // Warna ikon & teks di AppBar
           elevation: 1.0,
        ),
      ),
      // darkTheme: ThemeData(...), // <-- HAPUS ATAU KOMENTARI darkTheme
      // --- AKHIR PERUBAHAN TEMA ---
      home: LoginPage(),
      routes: {
        '/register': (ctx) => RegisterPage(),
        '/home': (ctx) => HomePage(),
        '/dashboard': (ctx) => DashboardPage(),
        '/admin-wisata': (ctx) => KelolaWisataPage(),
        '/admin-artikel': (ctx) => KelolaArtikelPage(),
        '/admin-pengguna': (ctx) => KelolaPenggunaPage(),
        '/edit-profile': (ctx) => const EditProfilePage(),
      },
    );
  }
}