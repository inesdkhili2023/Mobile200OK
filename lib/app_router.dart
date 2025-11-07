import 'package:go_router/go_router.dart';
import 'package:handcraft_reservation/features/ui/booking_success.dart';
import 'package:handcraft_reservation/features/ui/my_reservations_screen.dart';
import 'package:handcraft_reservation/features/ui/reservation_screen.dart';

final router = GoRouter(
  initialLocation: '/reservation',
  routes: [
    GoRoute(path: '/reservation', builder: (_, __) => const ReservationScreen()),
    GoRoute(path: '/success', builder: (_, __) => const BookingSuccess()),
    GoRoute(path: '/my-reservations', builder: (_, __) => const MyReservationsScreen()), 
  ],
);
