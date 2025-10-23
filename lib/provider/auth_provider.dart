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

final _fireAuth = FirebaseAuth.instance;

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Helper untuk pesan error yang lebih jelas
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
    required VoidCallback onSuccess, // Callback jika sukses
    required Function(String) onError,  // Callback jika error
  }) async {
    _setLoading(true);
    try {
      await _fireAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Jika berhasil, panggil callback sukses
      onSuccess();
    } on FirebaseAuthException catch (e) {
      // Jika error, panggil callback error dengan pesan
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
    required VoidCallback onSuccess, // Callback jika sukses
    required Function(String) onError,  // Callback jika error
  }) async {
    _setLoading(true);
    try {
      await _fireAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Jika berhasil, panggil callback sukses
      onSuccess();
    } on FirebaseAuthException catch (e) {
      // Jika error, panggil callback error dengan pesan
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