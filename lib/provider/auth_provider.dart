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
    // --- TAMBAHAN KODE ERROR UNTUK RE-AUTH & UPDATE ---
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        // Pesan ini bisa muncul saat re-auth jika user dihapus
        return 'Pengguna tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'requires-recent-login':
        // Error ini muncul jika user mencoba ganti email/pass tanpa re-auth baru-baru ini
        return 'Operasi ini memerlukan login ulang. Silakan masukkan password Anda saat ini.';
      case 'user-mismatch':
         // Error ini bisa muncul saat re-auth
        return 'Kredensial tidak sesuai dengan pengguna yang login.';
      case 'invalid-credential':
        // Error umum saat re-auth
        return 'Kredensial tidak valid.';
      // Tambahkan case lain jika diperlukan
      default:
        // Jika tidak dikenali, coba tampilkan pesan asli dari Firebase
        if (code.isNotEmpty) {
          return 'Error: $code';
        }
        return 'Terjadi error. Silakan coba lagi.';
    }
    // --- AKHIR TAMBAHAN KODE ERROR ---
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

      // --- TAMBAHAN: Update display name di Auth ---
      // Ini opsional tapi bagus agar nama muncul di tempat lain
      await userCredential.user?.updateDisplayName(nama);
      // --- AKHIR TAMBAHAN ---


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

  // =========================================================
  // --- TAMBAHAN FUNGSI BARU UNTUK EDIT PROFIL ---
  // =========================================================

  // 1. Fungsi untuk Re-autentikasi (memverifikasi password saat ini)
  Future<bool> reauthenticateUser({
    required String currentPassword,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    bool success = false;
    User? user = _fireAuth.currentUser;

    if (user != null && user.email != null) {
      // Buat kredensial dengan email dan password saat ini
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword, // <-- Jangan di-trim
      );
      try {
        // Coba re-autentikasi
        await user.reauthenticateWithCredential(credential);
        success = true; // Berhasil
      } on FirebaseAuthException catch (e) {
        onError(_mapErrorToMessage(e.code)); // Tampilkan error jika password salah, dll.
      } catch (e) {
        onError("Terjadi kesalahan saat re-autentikasi.");
        debugPrint("Re-auth Error: $e"); // Cetak error detail
      }
    } else {
      onError("Tidak dapat menemukan pengguna yang sedang login.");
    }
    _setLoading(false);
    return success;
  }

  // 2. Fungsi untuk Update Email (setelah re-autentikasi)
  Future<bool> updateUserEmail({
    required String newEmail,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    bool success = false;
    User? user = _fireAuth.currentUser;

    if (user != null) {
      try {
        // Update email di Firebase Authentication
        await user.verifyBeforeUpdateEmail(newEmail); // <-- Lebih aman pakai verify

        // Update email di Firestore juga
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });
        success = true; // Berhasil
        // Catatan: User mungkin perlu verifikasi email baru
        onError("Verifikasi email telah dikirim ke alamat baru Anda. Silakan cek email."); // Beri info

      } on FirebaseAuthException catch (e) {
        onError(_mapErrorToMessage(e.code)); // Tangani error (email sudah dipakai, dll.)
      } catch (e) {
        onError("Terjadi kesalahan saat memperbarui email.");
        debugPrint("Update Email Error: $e");
      }
    } else {
      onError("Tidak dapat menemukan pengguna yang sedang login.");
    }
    _setLoading(false);
    return success;
  }

  // 3. Fungsi untuk Update Password (setelah re-autentikasi)
  Future<bool> updateUserPassword({
    required String newPassword,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    bool success = false;
    User? user = _fireAuth.currentUser;

    if (user != null) {
      try {
        // Update password di Firebase Authentication
        await user.updatePassword(newPassword); // <-- Jangan di-trim
        success = true; // Berhasil
      } on FirebaseAuthException catch (e) {
        onError(_mapErrorToMessage(e.code)); // Tangani error (password lemah, dll.)
      } catch (e) {
        onError("Terjadi kesalahan saat memperbarui password.");
        debugPrint("Update Password Error: $e");
      }
    } else {
      onError("Tidak dapat menemukan pengguna yang sedang login.");
    }
    _setLoading(false);
    return success;
  }
  
  // 4. Fungsi untuk Update Nama (tidak perlu re-auth, hanya Firestore)
  Future<bool> updateUserName({
    required String newName,
    required Function(String) onError,
  }) async {
      _setLoading(true);
      bool success = false;
      User? user = _fireAuth.currentUser;

      if (user != null) {
        try {
          // --- TAMBAHAN: Update display name di Auth juga ---
          await user.updateDisplayName(newName);
          // --- AKHIR TAMBAHAN ---

          // Update nama di Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'nama': newName,
          });
          success = true; // Berhasil
        } catch (e) {
          onError("Terjadi kesalahan saat memperbarui nama.");
          debugPrint("Update Name Error: $e");
        }
      } else {
        onError("Tidak dapat menemukan pengguna yang sedang login.");
      }
       _setLoading(false);
       return success;
  }
  // ============================================
  // --- AKHIR TAMBAHAN FUNGSI EDIT PROFIL ---
  // ============================================
}