class WorkerAvailability {
  final int? id;
  final String workerId;        // id ouvrier sélectionné (string pour flex)
  final DateTime date;          // jour
  final List<String> slots;     // ["09:00-11:00","11:00-13:00"]
  final bool isHoliday;

  WorkerAvailability({
    this.id,
    required this.workerId,
    required this.date,
    required this.slots,
    this.isHoliday = false,
  });

  Map<String, Object?> toRow() => {
    'id': id,
    'worker_id': workerId,
    'date': date.toIso8601String(),
    'slots': slots.join(','),
    'is_holiday': isHoliday ? 1 : 0
  };

  static WorkerAvailability fromRow(Map<String, Object?> r) => WorkerAvailability(
    id: r['id'] as int?,
    workerId: r['worker_id'] as String,
    date: DateTime.parse(r['date'] as String),
    slots: (r['slots'] as String).split(',').where((e) => e.isNotEmpty).toList(),
    isHoliday: (r['is_holiday'] as int) == 1,
  );
}

class Booking {
  final int? id;
  final String workerId;
  final String workerName;
  final String city;               // location choisie
  final DateTime date;
  final String slot;               // "09:00-11:00"
  final String description;
  final String address;
  final int pax;
  final int priceCents;            // 6000 = 60 Dt
  final String status;             // created, paid, cancelled
  final String email;              // client email

  Booking({
    this.id,
    required this.workerId,
    required this.workerName,
    required this.city,
    required this.date,
    required this.slot,
    required this.description,
    required this.address,
    required this.pax,
    required this.priceCents,
    required this.status,
    required this.email,
  });

  Map<String, Object?> toRow() => {
    'id': id,
    'worker_id': workerId,
    'worker_name': workerName,
    'city': city,
    'date': date.toIso8601String(),
    'slot': slot,
    'description': description,
    'address': address,
    'pax': pax,
    'price_cents': priceCents,
    'status': status,
    'email': email,
  };

  static Booking fromRow(Map<String, Object?> r) => Booking(
    id: r['id'] as int?,
    workerId: r['worker_id'] as String,
    workerName: r['worker_name'] as String,
    city: r['city'] as String,
    date: DateTime.parse(r['date'] as String),
    slot: r['slot'] as String,
    description: r['description'] as String,
    address: r['address'] as String,
    pax: r['pax'] as int,
    priceCents: r['price_cents'] as int,
    status: r['status'] as String,
    email: r['email'] as String,
  );
}
