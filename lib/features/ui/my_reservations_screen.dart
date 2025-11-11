import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:service_app/features/ui/reservation_map_screen.dart';
import '../logic/providers.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';
import '../../features/ui/reschedule_screen.dart';

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

              Color statusColor;
              switch (b.status) {
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                case 'rescheduled':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = Colors.green;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text('${b.workerName} – ${b.city}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$date • ${b.slot}\n${b.description}'),
                      const SizedBox(height: 4),
                      Text(
                        'Statut : ${b.status}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: _buildActions(context, ref, b),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Booking b) {
  // Actions visibles uniquement si la réservation est active (payée)
  if (b.status == 'paid') {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔵 Bouton replanifier
        IconButton(
          icon: const Icon(Icons.schedule, color: Colors.blueAccent),
          tooltip: 'Replanifier',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RescheduleScreen(booking: b), // 👈 on passe la réservation sélectionnée
              ),
            );
            ref.invalidate(bookingsProvider); // 🔄 recharge la liste après modification
          },
        ),

        // 🔴 Bouton annuler
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          tooltip: 'Annuler la réservation',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirmer l’annulation'),
                content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
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

            if (confirm == true) {
              await ref.read(bookingRepoProvider).updateStatus(b.id!, 'cancelled');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Réservation annulée.')),
              );
              ref.invalidate(bookingsProvider); // ✅ recharge la liste
            }
          },
        ),
        IconButton(
  icon: const Icon(Icons.map, color: Colors.green),
  tooltip: 'Voir la carte',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationMapScreen(booking: b),
      ),
    );
  },
),
      ],
    );
  } else {
    // Si annulée ou replanifiée, pas d’action
    return const SizedBox(width: 10);
  }
}

}
