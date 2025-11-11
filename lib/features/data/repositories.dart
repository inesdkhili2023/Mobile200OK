import 'models.dart';
import 'availability_dao.dart';
import 'reservation_dao.dart';

class AvailabilityRepo {
  final AvailabilityDao dao;
  AvailabilityRepo(this.dao);

  Future<Map<DateTime, List<String>>> monthSlots(String workerId, DateTime month) async {
    final data = await dao.byMonth(workerId, month);
    final map = <DateTime, List<String>>{};
    for (final a in data) {
      final day = DateTime(a.date.year, a.date.month, a.date.day);
      map[day] = a.slots;
    }
    return map;
  }
}

class BookingRepo {
  final BookingDao dao;
  BookingRepo(this.dao);
  Future<int> create(Booking b) => dao.insert(b);
  Future<List<Booking>> getAll() => dao.getAll();
  Future<List<Booking>> getByEmail(String email) => dao.getByEmail(email);
  Future<List<String>> getBookedSlots(String workerId, DateTime date) =>
      dao.getBookedSlots(workerId, date);
  Future<void> updateStatus(int id, String newStatus) =>
    dao.updateStatus(id, newStatus);
    Future<void> update(Booking booking) => dao.update(booking);

}
