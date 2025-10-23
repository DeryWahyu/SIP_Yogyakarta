// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Pastikan file ini ada

// Impor provider dan halaman-halaman baru
import 'provider/auth_provider.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';

void main() async {
  // Pastikan Flutter dan Firebase terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // 1. Bungkus aplikasi dengan ChangeNotifierProvider
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
      title: 'Flutter Auth Demo', // Judul bisa diganti
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 2. Atur halaman login sebagai halaman utama
      home: LoginPage(),
      // 3. Definisikan rute untuk navigasi antar halaman
      routes: {
        '/register': (ctx) => RegisterPage(),
        '/home': (ctx) => HomePage(),
      },
    );
  }
}