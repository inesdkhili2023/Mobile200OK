import 'package:flutter/material.dart';
import 'package:handicraft/local_notification_service.dart';
import 'chats_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation avec gestion d'erreur
  try {
    await LocalNotificationService.initialize();
    print('✅ Notifications initialisées avec succès');
  } catch (e) {
    print('❌ Erreur initialisation notifications: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatsPage(),
    );
  }
}