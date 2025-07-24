import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintrack_apps/home/screen/tabs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintrack_apps/data/services/user_service.dart';

/// Instance Firebase Auth untuk otentikasi pengguna
final _firebase = FirebaseAuth.instance;

/// Widget utama untuk layar login/signup
///
/// Layar ini menyediakan antarmuka untuk pengguna melakukan:
/// - Login dengan email dan password
/// - Registrasi akun baru dengan username, email, dan password
/// - Validasi form input
/// - Error handling untuk berbagai skenario Firebase Auth
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Global key untuk form validation
  /// Digunakan untuk mengakses state form dan melakukan validasi
  final _form = GlobalKey<FormState>();

  /// Service untuk mengelola data pengguna di database lokal
  final UserService _userService = UserService();

  /// Flag untuk menentukan mode tampilan (login atau signup)
  /// true = mode login, false = mode signup
  var _isLogin = true;

  /// Variabel untuk menyimpan input email dari form
  var _enteredEmail = '';

  /// Variabel untuk menyimpan input password dari form
  var _enteredPassword = '';

  /// Variabel untuk menyimpan input username dari form (hanya untuk signup)
  var _enteredUsername = '';

  /// Flag untuk menunjukkan status loading
  /// Mencegah multiple submission dan menampilkan loading indicator
  var _isLoading = false;

  /// Fungsi utama untuk menangani proses login/signup
  ///
  /// Alur kerja:
  /// 1. Validasi form input
  /// 2. Simpan data form
  /// 3. Set status loading
  /// 4. Proses autentikasi berdasarkan mode (_isLogin)
  /// 5. Inisialisasi user di database lokal
  /// 6. Navigasi ke halaman utama
  /// 7. Handle error jika terjadi
  void _submit() async {
    // Validasi form menggunakan validator yang telah didefinisikan
    final isValid = _form.currentState!.validate();

    // Jika validasi gagal, hentikan proses
    if (!isValid) {
      return;
    }

    // Simpan semua nilai form ke variabel state
    _form.currentState!.save();

    // Set loading state untuk UI feedback
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // === PROSES LOGIN ===

        // Login menggunakan Firebase Auth dengan email dan password
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        // Inisialisasi data pengguna di database lokal setelah login berhasil
        await _userService.initializeUser();

        // Navigasi ke halaman utama aplikasi
        _navigateToHome();
      } else {
        // === PROSES SIGNUP ===

        // Buat akun baru di Firebase Auth
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        // Update display name di Firebase Auth jika username tersedia
        if (_enteredUsername.isNotEmpty) {
          await userCredentials.user!.updateDisplayName(_enteredUsername);
        }

        // Simpan data pengguna ke Firestore untuk referensi aplikasi
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'created_at': FieldValue
              .serverTimestamp(), // Timestamp server untuk konsistensi
        });

        // Inisialisasi data pengguna di database lokal
        await _userService.initializeUser();

        // Navigasi ke halaman utama aplikasi
        _navigateToHome();
      }
    } on FirebaseAuthException catch (error) {
      // === ERROR HANDLING FIREBASE AUTH ===

      // Handle berbagai kode error Firebase Auth dengan pesan bahasa Indonesia
      if (error.code == 'email-already-in-use') {
        _showError('Email sudah digunakan oleh akun lain');
      } else if (error.code == 'weak-password') {
        _showError('Password terlalu lemah');
      } else if (error.code == 'user-not-found') {
        _showError('Akun dengan email ini tidak ditemukan');
      } else if (error.code == 'wrong-password') {
        _showError('Password salah');
      } else {
        // Fallback untuk error Firebase Auth lainnya
        _showError(error.message ?? 'Authentikasi gagal');
      }
    } catch (error) {
      // Handle error umum yang bukan Firebase Auth
      _showError('Terjadi kesalahan: ${error.toString()}');
    } finally {
      // Reset loading state terlepas dari hasil operasi
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Menampilkan pesan error menggunakan SnackBar
  ///
  /// [message] Pesan error yang akan ditampilkan
  ///
  /// Clear snackbar sebelumnya untuk menghindari antrian pesan
  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Navigasi ke halaman utama aplikasi (TabsScreen)
  ///
  /// Menggunakan pushReplacement untuk mengganti seluruh stack navigasi
  /// sehingga pengguna tidak bisa kembali ke layar login dengan tombol back
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TabsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color merah maroon sesuai theme aplikasi
      backgroundColor: Color(0xFF660000),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // === LOGO APLIKASI ===
              Container(
                margin: EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/logo_fin.jpg'),
              ),

              // === FORM CARD ===
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // === USERNAME FIELD (HANYA UNTUK SIGNUP) ===
                          // Field username hanya muncul saat mode signup
                          if (!_isLogin)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Username',
                              ),
                              // Validasi username: wajib diisi untuk signup
                              validator: (value) {
                                if (!_isLogin &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Please enter a username.';
                                }
                                return null;
                              },
                              // Simpan nilai ke _enteredUsername
                              onSaved: (value) {
                                _enteredUsername = value ?? '';
                              },
                            ),

                          // === EMAIL FIELD ===
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                            ),
                            // Konfigurasi keyboard untuk input email
                            keyboardType: TextInputType.emailAddress,
                            autocorrect:
                                false, // Matikan autocorrect untuk email
                            textCapitalization: TextCapitalization
                                .none, // Tidak ada kapitalisasi otomatis
                            // Validasi email: wajib diisi dan harus mengandung @
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            // Simpan nilai ke _enteredEmail
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),

                          // === PASSWORD FIELD ===
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true, // Sembunyikan teks password
                            // Validasi password: minimal 6 karakter
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                            // Simpan nilai ke _enteredPassword
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),

                          SizedBox(height: 12),

                          // === SUBMIT BUTTON ===
                          ElevatedButton(
                            // Disable button saat loading untuk mencegah double tap
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color(0xFF660000), // Warna sesuai theme
                            ),
                            child: _isLoading
                                ? // Loading indicator saat proses autentikasi
                                const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : // Text button berubah berdasarkan mode
                                Text(
                                    _isLogin ? 'Login' : 'Signup',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),

                          // === TOGGLE BUTTON LOGIN/SIGNUP ===
                          // Button untuk beralih antara mode login dan signup
                          TextButton(
                            // Disable saat loading
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      // Toggle mode login/signup
                                      _isLogin = !_isLogin;
                                    });
                                  },
                            child: Text(_isLogin
                                ? 'Create an account' // Text saat mode login
                                : 'I already have an account'), // Text saat mode signup
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
