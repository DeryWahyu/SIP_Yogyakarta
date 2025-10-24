// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Impor provider dan halaman-halaman baru
import 'provider/auth_provider.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';
import 'screen/dashboard_page.dart'; // <-- BARU: Impor dashboard page

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
      home: LoginPage(),
      routes: {
        '/register': (ctx) => RegisterPage(),
        '/home': (ctx) => HomePage(),
        '/dashboard': (ctx) => DashboardPage(), // <-- BARU: Tambahkan rute dashboard
      },
    );
  }
}