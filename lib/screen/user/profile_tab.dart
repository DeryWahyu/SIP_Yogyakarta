// lib/screen/user/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../login_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          onPressed: () {
            authProvider.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (ctx) => LoginPage()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}