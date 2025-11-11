import '../../../core/db/app_db.dart';
import 'models.dart';

class BookingDao {
  Future<int> insert(Booking b) async {
    final db = await AppDb.instance;
    return db.insert('booking', b.toRow());
  }

  Future<List<Booking>> getAll() async {
  final db = await AppDb.instance;
  final rows = await db.query('booking', orderBy: 'date DESC');
  return rows.map(Booking.fromRow).toList();
}

Future<List<Booking>> getByEmail(String email) async {
  final db = await AppDb.instance;
  final rows = await db.query(
    'booking',
    where: 'email = ?',
    whereArgs: [email],
    orderBy: 'date DESC',
  );
  return rows.map(Booking.fromRow).toList();
}

Future<List<String>> getBookedSlots(String workerId, DateTime date) async {
  final db = await AppDb.instance;
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final rows = await db.query(
    'booking',
    where: 'worker_id = ? AND date >= ? AND date < ?',
    whereArgs: [
      workerId,
      startOfDay.toIso8601String(),
      endOfDay.toIso8601String(),
    ],
  );
  return rows.map((r) => r['slot'] as String).toList();
}

Future<void> updateStatus(int id, String newStatus) async {
  final db = await AppDb.instance;
  await db.update(
    'booking',
    {'status': newStatus},
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<void> update(Booking booking) async {
  final db = await AppDb.instance;
  await db.update(
    'booking',
    booking.toRow(),
    where: 'id = ?',
    whereArgs: [booking.id],
  );
}

}
