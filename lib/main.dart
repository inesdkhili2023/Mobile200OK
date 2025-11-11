import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod; // 👈 alias pour Riverpod
import 'package:provider/provider.dart' as legacy; // 👈 alias pour Provider classique

import 'package:service_app/core/notifications/local_notifs.dart';
import 'package:service_app/features/data/availability_dao.dart';
import 'package:service_app/features/ui/my_reservations_screen.dart';
import 'package:service_app/screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifs.init();
  await AvailabilityDao().seedDemo('worker_1');

  runApp(
    riverpod.ProviderScope( // ✅ Riverpod root
      child: legacy.MultiProvider( // ✅ Provider root
        providers: [
          legacy.ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandyCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/my-reservations': (context) => const MyReservationsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 on utilise l'alias "legacy" pour le Consumer du package provider
    return legacy.Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
