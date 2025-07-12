import 'package:fintrack_apps/home/screen/tabs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintrack_apps/features/auth/screen/login.dart';
import 'package:fintrack_apps/data/services/user_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<int>(
            future: _initializeUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mempersiapkan akun...'),
                      ],
                    ),
                  ),
                );
              }

              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${userSnapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: Text('Keluar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // User data initialized successfully
              return const TabsScreen();
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }

  Future<int> _initializeUserData() async {
    final userService = UserService();
    try {
      final userId = await userService.initializeUser();

      // Debug: Print user accounts
      await userService.debugUserAccounts();

      return userId;
    } catch (e) {
      print('Error initializing user data: $e');
      rethrow;
    }
  }
}
