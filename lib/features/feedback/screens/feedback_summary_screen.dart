import 'package:flutter/material.dart';
import '../data/feedback_db.dart';
import '../models/feedback_model.dart';
import '../widgets/bottom_navigation.dart';
import 'feedback_edit_screen.dart';

class FeedbackSummaryScreen extends StatefulWidget {
  const FeedbackSummaryScreen({super.key});

  @override
  State<FeedbackSummaryScreen> createState() => _FeedbackSummaryScreenState();
}

class _FeedbackSummaryScreenState extends State<FeedbackSummaryScreen> {
  List<FeedbackModel> feedbacks = [];
  double avgRating = 0.0;
  int inProgressCount = 0;
  int finishedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = FeedbackDb.instance;
    final all = await db.getAll();
    final avg = await db.getAverageRating();
    final counts = await db.countByStatus();

    setState(() {
      feedbacks = all;
      avgRating = avg;
      inProgressCount = counts['In Progress'] ?? 0;
      finishedCount = counts['Finished'] ?? 0;
    });
  }

  Future<void> _delete(int id) async {
    await FeedbackDb.instance.delete(id);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback supprimé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        title: const Text('Your Feedback Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Liste des feedbacks individuels
            Expanded(
              child: feedbacks.isEmpty
                  ? const Center(child: Text('Aucun feedback pour le moment'))
                  : ListView.separated(
                      itemCount: feedbacks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final f = feedbacks[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.build, size: 32, color: Colors.black87),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.service,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              Icons.star,
                                              size: 16,
                                              color: (i + 1) <= f.rating
                                                  ? Colors.orange
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (f.comment.isNotEmpty)
                                Text(
                                  f.comment,
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Navigate to update screen
                                        final updated = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FeedbackEditScreen(feedback: f),
                                          ),
                                        );
                                        if (updated == true) {
                                          await _loadData();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                         foregroundColor: Colors.white,   
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Update'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _delete(f.id!),
                                      style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,  
                                        backgroundColor: Colors.deepPurple,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Section statistiques: Prestations Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prestations Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('In Progress', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Text('$inProgressCount',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (inProgressCount + finishedCount) > 0
                        ? inProgressCount / (inProgressCount + finishedCount)
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.orange,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Finished', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Text('$finishedCount',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (inProgressCount + finishedCount) > 0
                        ? finishedCount / (inProgressCount + finishedCount)
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Average Rating: ${avgRating.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'based on ${feedbacks.length} feedbacks',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
