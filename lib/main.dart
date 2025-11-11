import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/screens/home_screen.dart'; // 👈 Ton HomeScreen
import 'providers/auth_provider.dart'; // 👈 Provider d'authentification de ton collègue
import 'login_page.dart'; // 👈 Page de login de ton collègue

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider()..init(),
      child: MaterialApp(
        title: 'HandyCraft',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
          useMaterial3: true,
        ),
        home: const AuthWrapper(), // 👈 Utilise le wrapper d'authentification
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomeScreen(), // 👈 Redirige vers TON HomeScreen
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Écran de chargement pendant la vérification
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est connecté → TON HomeScreen
        if (authProvider.isLoggedIn) {
          return const HomeScreen(); // 👈 Redirige vers ton écran après login
        } else {
          // Si non connecté → Page de LOGIN directement
          return const LoginPage(); // 👈 MODIFICATION ICI
        }
      },
    );
  }
}