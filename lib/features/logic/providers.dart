import 'package:handcraft_reservation/features/data/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/repositories.dart';
import '../data/availability_dao.dart';
import '../data/reservation_dao.dart';

final availabilityRepoProvider = Provider((_) => AvailabilityRepo(AvailabilityDao()));
final bookingRepoProvider = Provider((_) => BookingRepo(BookingDao()));

final selectedCityProvider = StateProvider<String?>((_) => null);
final selectedDateProvider = StateProvider<DateTime?>((_) => null);
final selectedSlotProvider = StateProvider<String?>((_) => null);
final paxProvider = StateProvider<int>((_) => 1);
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.read(bookingRepoProvider);
  return repo.getAll();
});

