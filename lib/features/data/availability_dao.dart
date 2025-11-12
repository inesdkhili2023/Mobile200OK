import '../../../core/db/app_db.dart';
import 'models.dart';

class AvailabilityDao {
  Future<void> seedDemo(String workerId) async {
    final db = await AppDb.instance;
    final now = DateTime.now();
     // 🟢 Coordonées fixes du worker 1 (ex : Tunis)
  const double workerLat = 36.8065;
  const double workerLng = 10.1815;
    for (int i = 0; i < 14; i++) {
      final d = now.add(Duration(days: i));
      final slots = (d.weekday == DateTime.sunday)
          ? <String>[]
          : ['09:00-11:00','11:00-13:00','14:00-16:00'];
      await db.insert('worker_availability', WorkerAvailability(
        workerId: workerId, 
        date: DateTime(d.year,d.month,d.day),
        slots: slots, 
        isHoliday: d.weekday == DateTime.sunday,
        latitude: workerLat,
        longitude: workerLng,
      ).toRow());
    }
  }

  Future<List<WorkerAvailability>> byMonth(String workerId, DateTime month) async {
    final db = await AppDb.instance;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await db.query('worker_availability',
      where: 'worker_id = ? AND date >= ? AND date < ?',
      whereArgs: [workerId, start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map(WorkerAvailability.fromRow).toList();
  }
}
