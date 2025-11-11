import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/models.dart';

class ReservationMapScreen extends StatelessWidget {
  final Booking booking;

  const ReservationMapScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final clientLat = booking.latitude;
    final clientLng = booking.longitude;

    if (clientLat == null || clientLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carte réservation')),
        body: const Center(
          child: Text(
            'Aucune position client enregistrée pour cette réservation.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 🟢 Position du client
    final clientPos = LatLng(clientLat, clientLng);

    // 🟢 Récupère la position du worker à partir du workerId
    // (dans ton cas, worker_1)
    final workerLat = 36.8065; // Tunis (exemple fixe)
    final workerLng = 10.1815;
    final workerPos = LatLng(workerLat, workerLng);

    return Scaffold(
      appBar: AppBar(title: const Text('Localisation réservation')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: clientPos,
          initialZoom: 13,
        ),
        children: [
          // 🔹 Fond OpenStreetMap
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),

          // 🔹 Markers client et worker
          MarkerLayer(markers: [
            Marker(
              point: clientPos,
              width: 60,
              height: 60,
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.red, size: 40),
            ),
            Marker(
              point: workerPos,
              width: 60,
              height: 60,
              child: const Icon(Icons.home_repair_service,
                  color: Colors.blue, size: 40),
            ),
          ]),
        ],
      ),
    );
  }
}
