import 'package:fintrack_apps/home/screen/dompet.dart';
import 'package:fintrack_apps/home/screen/home.dart';
import 'package:fintrack_apps/home/screen/rekap.dart';
import 'package:flutter/material.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedPageIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    RekapScreen(),
    DompetScreen(),
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
          onTap: _selectPage,
          currentIndex: _selectedPageIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              label: 'Rekap',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Dompet',
            ),
            //BottomNavigationBarItem(
            //icon: Icon(Icons.delete),
            //label: 'Hapus',
            //),
          ]),
    );
  }
}
