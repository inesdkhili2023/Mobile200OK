import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:service_app/features/ui/my_reservations_screen.dart';
import 'package:service_app/models/worker_model.dart';
import 'package:service_app/screens/home_screen.dart'; // 👈 import du HomeScreen
import '../logic/providers.dart';
import 'location_picker.dart';
import 'calendar_slots.dart';
import 'booking_form.dart';

class ReservationScreen extends ConsumerWidget {
  final WorkerModel worker; // ✅ le worker sélectionné

  const ReservationScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final date = ref.watch(selectedDateProvider);
    final slot = ref.watch(selectedSlotProvider);
    final pax = ref.watch(paxProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Réservation — ${worker.fullName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Retour à l’accueil',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mes réservations',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (city != null && date != null && slot != null)
                      ? () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => BookingForm(
                              worker: worker, // ✅ passe le worker ici
                              city: city,
                              date: date,
                              slot: slot,
                              pax: pax,
                            ),
                          )
                      : null,
                  child: Text('Payer ${worker.priceText} →'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(worker.fullName),
            subtitle: Text(worker.workType),
            trailing: Text(
              worker.priceText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(city ?? 'Choisir une ville'),
            trailing: const Icon(Icons.my_location),
            onTap: () async {
              final sel = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LocationPicker()),
              );

              if (sel != null) {
                if (sel is Map<String, dynamic>) {
                  ref.read(selectedCityProvider.notifier).state = sel['city'];
                  ref.read(userLatProvider.notifier).state = sel['lat'];
                  ref.read(userLngProvider.notifier).state = sel['lng'];
                } else if (sel is String) {
                  ref.read(selectedCityProvider.notifier).state = sel;
                }
              }
            },
          ),
          const SizedBox(height: 8),
          const CalendarSlots(), // calendrier + créneaux
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.group),
            title: Text('PAX: ${ref.watch(paxProvider)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: () => ref.read(paxProvider.notifier).state =
                    (pax > 1) ? pax - 1 : 1,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(paxProvider.notifier).state = pax + 1,
                icon: const Icon(Icons.add),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
