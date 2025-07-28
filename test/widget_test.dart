import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fintrack_apps/main.dart';

class MockUser extends Mock implements User {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  final User? mockUser;

  MockFirebaseAuth({this.mockUser});

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(mockUser); // Ganti dengan null untuk user belum login
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock inisialisasi Firebase
    //await Firebase.initializeApp();
  });

  testWidgets('Menampilkan TabsScreen jika user sudah login', (WidgetTester tester) async {
    final mockUser = MockUser();
    final mockAuth = MockFirebaseAuth(mockUser: mockUser);

    // Jalankan widget dengan FirebaseAuth palsu
    await tester.pumpWidget(
      MaterialApp(
        home: StreamBuilder<User?>(
          stream: mockAuth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            if (snapshot.hasData) {
              return const Text('Halaman Home'); // Ganti sesuai isi TabsScreen kamu
            }

            return const Text('Halaman Login'); // Ganti sesuai isi StartScreen kamu
          },
        ),
      ),
    );

    await tester.pump(); // untuk memproses stream

    expect(find.text('Halaman Home'), findsOneWidget);
  });
}
