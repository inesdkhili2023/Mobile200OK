import 'package:flutter/material.dart';
import 'features/feedback/screens/feedback_home_screen.dart';
import 'features/feedback/services/notification_service.dart';

void main() async {
  // Nécessaire pour initialiser avant runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service de notifications
  await NotificationService.instance.initialize();
  
  runApp(const FeedbackApp());
}

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Historique & Feedback',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F2FF),
      ),
      home: const FeedbackHomeScreen(),
    );
  }
}
