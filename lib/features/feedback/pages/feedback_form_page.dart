import 'package:flutter/material.dart';
import '../widgets/rating_stars.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  // Données simulées (avant la DB)
  final List<Map<String, dynamic>> _feedbacks = [
    {
      'service': 'Electrician',
      'status': 'In Progress',
      'rating': 0,
      'comment': '',
      'price': '89DT',
    },
    {
      'service': 'Plumber',
      'status': 'Finished',
      'rating': 4,
      'comment': 'Fast and efficient',
      'price': '109DT',
    },
  ];

  // Form
  final _formKey = GlobalKey<FormState>();
  final _serviceCtrl = TextEditingController(text: 'Electrician');
  final _commentCtrl = TextEditingController();
  int _rating = 0;

  double get _averageRating {
    final rated = _feedbacks.where((f) => (f['rating'] as int) > 0).toList();
    if (rated.isEmpty) return 0;
    final total =
        rated.fold<int>(0, (sum, f) => sum + (f['rating'] as int));
    return total / rated.length;
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    // Ajout “front-only”
    setState(() {
      _feedbacks.insert(0, {
        'service': _serviceCtrl.text.trim(),
        'status': 'Finished',
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'price': '—',
      });
      _commentCtrl.clear();
      _rating = 0;
    });

    // Pop-up de confirmation
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFDCCAF7),
              child: Icon(Icons.check_rounded,
                  color: Color(0xFF7E57C2), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('feedback Submitted',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text(
              'Thank you for your feedback!\nYour review helps us improve our services.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ok'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.build_rounded, size: 36, color: Colors.black54),
        title: Text(item['service']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['price'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle,
                    size: 10,
                    color: item['status'] == 'Finished'
                        ? Colors.green
                        : Colors.orange),
                const SizedBox(width: 6),
                Text(item['status']),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (i) => Icon(
              Icons.star_rounded,
              color: i < (item['rating'] as int)
                  ? Colors.amber
                  : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique & Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bandeau "Average Rating"
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Average Rating: ⭐ ${_averageRating.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),

            // Liste des prestations
            Expanded(
              child: ListView.builder(
                itemCount: _feedbacks.length,
                itemBuilder: (_, i) => _buildServiceCard(_feedbacks[i]),
              ),
            ),

            // Formulaire (ton bloc blanc en bas)
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('your feedback',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Text',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Please write a comment';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('rating',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    RatingStars(
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom bar simple (comme Figma)
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Transaction'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
