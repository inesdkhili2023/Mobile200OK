import 'package:flutter/material.dart';
import '../../../services/location_service.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final items = [
    'Tunis',
    'Ariana',
    'Lac',
    'Marsa',
    'Sidi Bou Said',
    'Bizerte',
    'Gafsa'
  ];

  bool loading = false;
  String? detectedAddress;

  Future<void> _detectPosition() async {
    setState(() => loading = true);
    final result = await LocationService.pickUserLocation();
    setState(() => loading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de détecter la position.')),
      );
      return;
    }

    setState(() {
      detectedAddress = result['address'];
    });

    // ✅ On renvoie les données à la page précédente
    Navigator.pop(context, {
      'city': result['address'],
      'lat': result['lat'],
      'lng': result['lng'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une position')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Saisir une adresse ou une ville...',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(items[i]),
                onTap: () => Navigator.pop(context, {
                  'city': items[i],
                  'lat': null,
                  'lng': null,
                }),
              ),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Localiser ma position actuelle'),
                onPressed: _detectPosition,
              ),
            ),
          )
        ],
      ),
    );
  }
}
