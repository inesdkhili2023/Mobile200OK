import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../logic/providers.dart';
import 'location_picker.dart';
import 'calendar_slots.dart';
import 'booking_form.dart';

class ReservationScreen extends ConsumerWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final date = ref.watch(selectedDateProvider);
    final slot = ref.watch(selectedSlotProvider);
    final pax  = ref.watch(paxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation'),
      actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mes réservations',
            onPressed: () => context.push('/my-reservations'),
          ),
        ],),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {}, child: const Text('Chat')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (city!=null && date!=null && slot!=null)
                      ? () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => BookingForm(city: city, date: date, slot: slot, pax: pax),
                        )
                      : null,
                  child: const Text('Payment →'),
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
            leading: const Icon(Icons.location_on),
            title: Text(city ?? 'Choisir une ville'),
            trailing: const Icon(Icons.my_location),
            onTap: () async {
              final sel = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationPicker()));
              if (sel != null) ref.read(selectedCityProvider.notifier).state = sel as String;
            },
          ),
          const SizedBox(height: 8),
          const CalendarSlots(), // calendrier + créneaux
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.group),
            title: Text('PAX: ${ref.watch(paxProvider)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: ()=> ref.read(paxProvider.notifier).state = (pax>1)?pax-1:1, icon: const Icon(Icons.remove)),
              IconButton(onPressed: ()=> ref.read(paxProvider.notifier).state = pax+1, icon: const Icon(Icons.add)),
            ]),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text('60 Dt'),
            trailing: const Icon(Icons.expand_more),
          ),
        ],
      ),
    );
  }
}
