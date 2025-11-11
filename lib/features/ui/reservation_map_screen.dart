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

    final clientPos = LatLng(clientLat, clientLng);
    final workerPos = _workerPositionForCity(booking.city, clientLat, clientLng);

    return Scaffold(
      appBar: AppBar(title: const Text('Localisation réservation')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: clientPos,
          initialZoom: 13,
        ),
        children: [
          // 🔹 Fond de carte OpenStreetMap
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
              child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
            ),
            Marker(
              point: workerPos,
              width: 60,
              height: 60,
              child: const Icon(Icons.home_repair_service, color: Colors.blue, size: 40),
            ),
          ]),
        ],
      ),
    );
  }

  LatLng _workerPositionForCity(String city, double clientLat, double clientLng) {
    switch (city.toLowerCase()) {
      case 'tunis':
        return const LatLng(36.8065, 10.1815);
      case 'ariana':
        return const LatLng(36.8688, 10.1647);
      case 'lac':
        return const LatLng(36.8340, 10.2430);
      case 'marsa':
        return const LatLng(36.8780, 10.3247);
      case 'sidi bou said':
        return const LatLng(36.8700, 10.3419);
      case 'bizerte':
        return const LatLng(37.2746, 9.8739);
      case 'gafsa':
        return const LatLng(34.4250, 8.7842);
      default:
        // Si ville inconnue → worker proche du client
        return LatLng(clientLat + 0.002, clientLng + 0.002);
    }
  }
}
