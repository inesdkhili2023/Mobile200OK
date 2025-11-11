import 'package:flutter/material.dart';
import '../data/feedback_db.dart';
import '../models/feedback_model.dart';
import '../services/moderation_service.dart';
import 'feedback_updated_screen.dart';

class FeedbackEditScreen extends StatefulWidget {
  final FeedbackModel feedback;
  
  const FeedbackEditScreen({super.key, required this.feedback});

  @override
  State<FeedbackEditScreen> createState() => _FeedbackEditScreenState();
}

class _FeedbackEditScreenState extends State<FeedbackEditScreen> {
  late TextEditingController _commentCtrl;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController(text: widget.feedback.comment);
    _rating = widget.feedback.rating;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a rating')),
      );
      return;
    }

    // 🔴 Vérification de modération locale avant mise à jour
    final comment = _commentCtrl.text.trim();
    if (comment.isNotEmpty && ModerationService.instance.containsBadWord(comment)) {
      _showInsultAlert();
      return;
    }

    final updated = FeedbackModel(
      id: widget.feedback.id,
      service: widget.feedback.service,
      status: widget.feedback.status,
      rating: _rating,
      comment: comment,
      priceLabel: widget.feedback.priceLabel,
      createdAt: widget.feedback.createdAt,
    );

    await FeedbackDb.instance.update(updated);

    if (!mounted) return;
    
    // Navigate to success screen
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const FeedbackUpdatedScreen(),
        fullscreenDialog: true,
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        title: const Text('Edit Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service info
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  const Icon(Icons.build, size: 40, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.feedback.service,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: widget.feedback.status == 'Finished'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.feedback.status,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Comment field
            Text(
              'Your Feedback',
              style: TextStyle(
                color: Colors.black.withOpacity(0.65),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rating
            Text(
              'Rating',
              style: TextStyle(
                color: Colors.black.withOpacity(0.65),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    Icons.star,
                    color: (i + 1) <= _rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Update Feedback',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
