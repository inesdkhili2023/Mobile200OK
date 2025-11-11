import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../logic/providers.dart';
import '../data/models.dart';
import '../../features/ui/calendar_slots.dart';


class RescheduleScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const RescheduleScreen({super.key, required this.booking});

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replanifier la réservation'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choisissez une nouvelle date et un créneau horaire pour votre service :',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // ✅ Ton calendrier interactif
            Expanded(
              child: CalendarSlots(
                onSlotSelected: (date, slot) {
                  setState(() {
                    _selectedDate = date;
                    _selectedSlot = slot;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_selectedDate != null && _selectedSlot != null)
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer la replanification'),
                          content: Text(
                            'Souhaitez-vous déplacer votre réservation au '
                            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                            '(${_selectedSlot!}) ?',
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Non')),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Oui')),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      final updated = widget.booking.copyWith(
                        date: _selectedDate!,
                        slot: _selectedSlot!,
                        status: 'rescheduled',
                      );

                      await ref.read(bookingRepoProvider).update(updated);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Réservation replanifiée avec succès.')),
                        );
                        Navigator.pop(context); // retourne vers Mes Réservations
                      }
                    }
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Confirmer la nouvelle date'),
            ),
          ],
        ),
      ),
    );
  }
}
