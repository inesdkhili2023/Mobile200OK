import 'package:flutter/material.dart';
import '../data/feedback_db.dart';
import '../models/feedback_model.dart';
import '../widgets/bottom_navigation.dart';
import '../services/moderation_service.dart';
import '../services/notification_service.dart';
import 'feedback_submitted_screen.dart';
import 'feedback_summary_screen.dart';

class FeedbackHomeScreen extends StatefulWidget {
  const FeedbackHomeScreen({super.key});

  @override
  State<FeedbackHomeScreen> createState() => _FeedbackHomeScreenState();
}

class _FeedbackHomeScreenState extends State<FeedbackHomeScreen> {
  // Services "mockés" pour l'historique (comme Figma)
  final List<Map<String, String>> services = const [
    {'service': 'Electrician', 'price': '—', 'status': 'Finished'},
    {'service': 'Electrician', 'price': '89DT', 'status': 'In Progress'},
    {'service': 'Plumber', 'price': '109DT', 'status': 'Finished'},
  ];

  // état sélection + formulaire
  int? selectedIndex;
  int formRating = 0;
  final commentCtrl = TextEditingController();
  final _formKey = GlobalKey();

  // data venant de SQLite
  double avgAll = 0.0;
  final Map<String, double> avgByService = {};

  @override
  void initState() {
    super.initState();
    _initModeration();
    _refreshStats();
  }

  Future<void> _initModeration() async {
    await ModerationService.instance.loadBadWords();
  }

  Future<void> _refreshStats() async {
    final db = FeedbackDb.instance;
    final a = await db.getAverageRating();
    final m = <String, double>{};
    for (final s in services) {
      m[s['service']!] = await db.getAverageForService(s['service']!);
    }
    setState(() {
      avgAll = a;
      avgByService
        ..clear()
        ..addAll(m);
    });
  }

  Future<void> _submit() async {
    if (selectedIndex == null) {
      _snack('Please select a service above before submitting.');
      return;
    }
    if (formRating == 0) {
      _snack('Please add a rating.');
      return;
    }

    // Validation du commentaire
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _snack('Please tap your feedback in the comment field.');
      return;
    }

    // 🔴 Vérification de modération locale
    if (ModerationService.instance.containsBadWord(comment)) {
      _showInsultAlert();
      return;
    }

    final s = services[selectedIndex!];
    final model = FeedbackModel(
      service: s['service']!,
      status: s['status']!,
      rating: formRating,
      comment: comment,
      priceLabel: s['price']!,
      createdAt: DateTime.now(),
    );

    await FeedbackDb.instance.insert(model);
    
    // 🔔 API Notification - Envoyer "Merci pour votre avis"
    await NotificationService.instance.sendFeedbackThankYou();
    
    commentCtrl.clear();
    setState(() {
      formRating = 0;
    });

    // Navigate to the confirmation screen
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const FeedbackSubmittedScreen(),
      fullscreenDialog: true,
    ));

    // After confirmation, refresh stats
    await _refreshStats();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showInsultAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Inappropriate Content'),
        content: const Text(
          'This message contains an insult. Please try again with respectful language.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique & Feedback'),
        backgroundColor: Colors.deepPurple.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Feedback Summary',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FeedbackSummaryScreen(),
              ));
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // moyenne globale
            Row(
              children: [
                const Text('Average Rating: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(' ${avgAll.toStringAsFixed(1)} / 5',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // liste des prestations
            Expanded(
              child: ListView.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = services[index];
                  final selected = selectedIndex == index;

                  return InkWell(
                    onTap: () => setState(() => selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.deepPurple.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.deepPurple : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build, color: Colors.grey, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['service']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 16)),
                                Text(s['price']!,
                                    style: const TextStyle(color: Colors.black54)),
                                Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 10,
                                        color: s['status'] == 'Finished'
                                            ? Colors.green
                                            : Colors.orange),
                                    const SizedBox(width: 6),
                                    Text(s['status']!,
                                        style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // bouton Feedback
                          ElevatedButton(
                            onPressed: () {
                              setState(() => selectedIndex = index);
                              // scroll to form area
                              Future.delayed(const Duration(milliseconds: 150), () {
                                Scrollable.ensureVisible(
                                  _formKey.currentContext!,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selected ? Colors.deepPurple : Colors.deepPurple.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 0,
                            ),
                            child: const Text('feedback', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // formulaire
            Align(
              alignment: Alignment.centerLeft,
              child: Text('your feedback',
                  style:
                      TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 14)),
            ),
            const SizedBox(height: 6),
            Container(
              key: _formKey,
              child: TextField(
                controller: commentCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Text',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('rating',
                  style:
                      TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 14)),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  iconSize: 26,
                  onPressed: () => setState(() => formRating = i + 1),
                  icon: Icon(
                    Icons.star,
                    color: (i + 1) <= formRating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
