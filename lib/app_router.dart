import 'package:go_router/go_router.dart';

import 'package:service_app/features/ui/booking_success.dart';
import 'package:service_app/features/ui/my_reservations_screen.dart';
import 'package:service_app/features/ui/reservation_screen.dart';
import 'package:service_app/models/worker_model.dart';

final router = GoRouter(
  initialLocation: '/reservation',
  routes: [
    GoRoute(
  path: '/reservation',
  builder: (context, state) {
    final worker = state.extra as WorkerModel;
    return ReservationScreen(worker: worker);
  },
),

    GoRoute(path: '/success', builder: (_, __) => const BookingSuccess()),
    GoRoute(path: '/my-reservations', builder: (_, __) => const MyReservationsScreen()), 
  ],
);
