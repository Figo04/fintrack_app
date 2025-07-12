import 'package:fintrack_apps/core/themes/color.dart';
import 'package:fintrack_apps/features/auth/screen/login.dart';
import 'package:fintrack_apps/home/screen/tabs.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas konfigurasi gambar
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(400),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  top: 70,
                  left: 60,
                  right: 117,
                  child: Image.asset(
                    'assets/images/login_fint.png', 
                    height: 350,
                  ),
                )
              ],
            ),
          ),

          // Bagian bawah konfigurasi teks dan tombol
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Uang Jadi Lebih\nMudah Dengan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'FINTRACK',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Catat pemasukan dan pengeluaranmu dengan cara yang simpel, cepat, dan menyenangkan. Aplikasi ini dirancang untuk bantu kamu lebih bijak dalam mengatur keuangan sehari-hari.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TabsScreen()),
                      );
                    },
                    child: Text(
                      'Mulai Sekarang',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
