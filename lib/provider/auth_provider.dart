// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final _fireAuth  = FirebaseAuth.instance;
// class AuthProvider extends ChangeNotifier {
//   final form = GlobalKey<FormState>();

//   var islogin = true;
//   var enteredEmail = '';
//   var enteredPassword = '';

//   void submit() async {
//     final isvalid = form.currentState!.validate();

//     if(!isvalid) {
//       return;
//     }

//     form.currentState!.save();

//     try{
//       if(islogin){
//         final UserCredential userCredential = await _fireAuth.signInWithEmailAndPassword(
//           email: enteredEmail,
//           password: enteredPassword,
//         );
//       } else {
//         final UserCredential userCredential = await _fireAuth.createUserWithEmailAndPassword(
//           email: enteredEmail,
//           password: enteredPassword,
//         );
//       }
//     }catch(e){
//       if(e is FirebaseAuthException){
//         if(e.code == 'Email-already-in-use'){
//           print("Email sudah digunakan");
//         }
//       }
//     }
//     notifyListeners();
//   }
// }

// lib/provider/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// BARU: Impor firestore
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireAuth = FirebaseAuth.instance;
// BARU: Buat instance firestore
final _firestore = FirebaseFirestore.instance;

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapErrorToMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      default:
        return 'Terjadi error. Silakan coba lagi.';
    }
  }

  // --- FUNGSI UNTUK LOGIN ---
  Future<void> signIn({
    required String email,
    required String password,
    // BARU: onSuccess sekarang mengembalikan String (role)
    required Function(String role) onSuccess,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    try {
      // 1. Login dengan Auth
      final UserCredential userCredential =
          await _fireAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Jika sukses, ambil data user dari Firestore
      if (userCredential.user != null) {
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        // 3. Cek apakah dokumen ada dan punya role
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? 'user'; // Default ke 'user' jika tidak ada
          onSuccess(role); // Kirim role ke login page
        } else {
          // Kasus aneh: user ada di Auth tapi tidak di Firestore
          // Kita anggap sebagai user biasa
          onSuccess('user');
        }
      }
    } on FirebaseAuthException catch (e) {
      onError(_mapErrorToMessage(e.code));
    } catch (e) {
      onError("Terjadi kesalahan, silakan coba lagi.");
    }
    _setLoading(false);
  }

  // --- FUNGSI UNTUK REGISTRASI ---
  Future<void> signUp({
    required String email,
    required String password,
    required String nama, // BARU: Tambahkan parameter nama
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    try {
      // 1. Buat user di Firebase Auth
      final UserCredential userCredential =
          await _fireAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Jika sukses, simpan data user ke Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'nama': nama,
          'email': email,
          'role': 'user', // BARU: Tetapkan role default sebagai 'user'
        });
      }

      onSuccess();
    } on FirebaseAuthException catch (e) {
      onError(_mapErrorToMessage(e.code));
    } catch (e) {
      onError("Terjadi kesalahan, silakan coba lagi.");
    }
    _setLoading(false);
  }

  // --- FUNGSI UNTUK LOGOUT ---
  Future<void> signOut() async {
    await _fireAuth.signOut();
  }
}