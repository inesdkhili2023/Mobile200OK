import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../logic/providers.dart';
import '../data/models.dart';

class CalendarSlots extends ConsumerStatefulWidget {
  const CalendarSlots({super.key});

  @override
  ConsumerState<CalendarSlots> createState() => _CalendarSlotsState();
}

class _CalendarSlotsState extends ConsumerState<CalendarSlots> {
  DateTime _focused = DateTime.now();
  late Future<List<WorkerAvailability>> _availabilities;
  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  void _loadAvailabilities() {
    _availabilities =
        ref.read(availabilityRepoProvider).dao.byMonth('worker_1', _focused);
  }

  Future<void> _loadBookedSlots(DateTime date) async {
    final repo = ref.read(bookingRepoProvider);
    final booked = await repo.getBookedSlots('worker_1', date);
    setState(() => _bookedSlots = booked);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);

    return FutureBuilder<List<WorkerAvailability>>(
      future: _availabilities,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        final data = snapshot.data ?? [];
        final availableDays = {
          for (var a in data)
            DateTime(a.date.year, a.date.month, a.date.day): a,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focused,
              selectedDayPredicate: (day) =>
                  selectedDate != null &&
                  day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day,
              onDaySelected: (selected, focused) async {
                ref.read(selectedDateProvider.notifier).state = selected;
                ref.read(selectedSlotProvider.notifier).state = null;
                setState(() => _focused = focused);
                await _loadBookedSlots(selected); // ✅ récupère les slots réservés du jour
              },
              onPageChanged: (focused) {
                setState(() {
                  _focused = focused;
                  _loadAvailabilities();
                });
              },
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
              ),
            ),
            const SizedBox(height: 12),
            if (selectedDate == null)
              const Text('Sélectionnez une date pour voir les créneaux disponibles.')
            else
              _buildColoredSlots(selectedDate, availableDays, selectedSlot),
          ],
        );
      },
    );
  }

  Widget _buildColoredSlots(
    DateTime selectedDate,
    Map<DateTime, WorkerAvailability> availableDays,
    String? selectedSlot,
  ) {
    final key =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final avail = availableDays[key];

    if (avail == null) {
      return const Text('Aucune donnée de disponibilité pour ce jour.');
    }

    final slots = avail.slots;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in slots)
          ChoiceChip(
            label: Text(
              s,
              style: TextStyle(
                color: _bookedSlots.contains(s)
                    ? Colors.red.shade900
                    : Colors.white,
              ),
            ),
            selected: selectedSlot == s,
            onSelected: _bookedSlots.contains(s)
                ? null // désactivé si réservé
                : (_) =>
                    ref.read(selectedSlotProvider.notifier).state = s,
            selectedColor: Colors.green.shade600,
            backgroundColor: _bookedSlots.contains(s)
                ? Colors.red.shade300
                : Colors.green.shade400,
          ),
      ],
    );
  }
}
