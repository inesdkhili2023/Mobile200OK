import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingSuccess extends StatefulWidget {
  const BookingSuccess({super.key});

  @override
  State<BookingSuccess> createState() => _BookingSuccessState();
}

class _BookingSuccessState extends State<BookingSuccess> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/reservation'); // ✅ retour automatique
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.check_circle, size: 120, color: Colors.green),
          SizedBox(height: 16),
          Text('Réservation confirmée !', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }
}
