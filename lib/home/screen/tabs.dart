import 'package:fintrack_apps/home/screen/dompet.dart';
import 'package:fintrack_apps/home/screen/home.dart';
import 'package:fintrack_apps/home/screen/rekap.dart';
import 'package:flutter/material.dart';

/// Widget utama untuk menampilkan layar dengan navigasi tab
///
/// [TabsScreen] adalah StatefulWidget yang menyediakan navigasi bottom tab
/// untuk aplikasi FinTrack. Widget ini mengelola perpindahan antara
/// layar Home, Rekap, dan Dompet menggunakan BottomNavigationBar.
class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

/// State class untuk TabsScreen yang mengelola navigasi tab
class _TabsScreenState extends State<TabsScreen> {
  /// Index halaman yang sedang aktif/dipilih
  ///
  /// Nilai default adalah 0 (HomeScreen)
  /// - 0: HomeScreen
  /// - 1: RekapScreen
  /// - 2: DompetScreen (belum diimplementasi dalam list _pages)
  int _selectedPageIndex = 0;

  /// Daftar widget halaman yang dapat diakses melalui bottom navigation
  ///
  /// Saat ini hanya berisi 2 halaman:
  /// - Index 0: HomeScreen - Halaman utama aplikasi
  /// - Index 1: RekapScreen - Halaman rekap transaksi
  ///
  /// Note: DompetScreen belum ditambahkan ke dalam list ini,
  /// meskipun sudah ada tab untuk Dompet di BottomNavigationBar
  final List<Widget> _pages = [
    HomeScreen(),
    RekapScreen(),
    DompetScreen(),
  ];

  /// Fungsi untuk mengubah halaman yang aktif
  ///
  /// [index] - Index halaman yang akan ditampilkan
  ///
  /// Fungsi ini dipanggil ketika user menekan salah satu tab
  /// di BottomNavigationBar dan akan mengupdate state untuk
  /// menampilkan halaman yang sesuai
  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai dengan index yang dipilih
      body: _pages[_selectedPageIndex],

      // Bottom navigation bar dengan 3 tab
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage, // Callback ketika tab ditekan
        currentIndex: _selectedPageIndex, // Tab yang sedang aktif
        items: const [
          // Tab Home
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Tab Rekap
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Rekap',
          ),
          // Tab Dompet
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Dompet',
          ),
        ],
      ),
    );
  }
}
