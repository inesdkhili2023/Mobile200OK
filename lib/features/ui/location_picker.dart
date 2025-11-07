import 'package:flutter/material.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({super.key});
  @override
  Widget build(BuildContext context) {
    final items = ['Tunis','Ariana','Lac','Marsa','Sidi Bou Said','Bizerte','Gafsa'];
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Position')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(items[i]),
                trailing: i==0 ? const Text('récente', style: TextStyle(color: Colors.grey)) : null,
                onTap: ()=> Navigator.pop(context, items[i]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(onPressed: ()=> Navigator.pop(context, items.first), child: const Text('Valider')),
            ),
          )
        ],
      ),
    );
  }
}
