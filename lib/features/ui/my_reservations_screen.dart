import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../logic/providers.dart';
import 'package:intl/intl.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        centerTitle: true,
      ),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune réservation trouvée.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];
              final date = DateFormat('dd MMM yyyy').format(b.date);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text('${b.workerName} – ${b.city}'),
                  subtitle: Text('$date • ${b.slot}\n${b.description}'),
                  trailing: Text(
                    '${(b.priceCents / 100).toStringAsFixed(0)} DT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
