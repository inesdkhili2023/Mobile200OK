import 'package:flutter/services.dart';

class ModerationService {
  ModerationService._();
  static final ModerationService instance = ModerationService._();

  List<String> _badWords = [];
  bool _isLoaded = false;

  /// Charge la liste des mots interdits depuis le fichier assets/bad_words.txt
  Future<void> loadBadWords() async {
    if (_isLoaded) return;
    
    try {
      final content = await rootBundle.loadString('assets/bad_words.txt');
      _badWords = content
          .split('\n')
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toList();
      _isLoaded = true;
    } catch (e) {
      print('Erreur lors du chargement des mots interdits: $e');
      _badWords = [];
    }
  }

  /// Vérifie si le texte contient un mot interdit
  /// Retourne true si un mot interdit est détecté
  bool containsBadWord(String text) {
    if (!_isLoaded) {
      throw Exception('Bad words list not loaded. Call loadBadWords() first.');
    }

    final lowerText = text.toLowerCase();
    
    // Vérifie chaque mot interdit
    for (final badWord in _badWords) {
      // Recherche le mot comme mot complet (avec espaces ou ponctuation autour)
      final pattern = RegExp(r'\b' + RegExp.escape(badWord) + r'\b');
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }
    
    return false;
  }

  /// Retourne la liste des mots interdits trouvés dans le texte
  List<String> findBadWords(String text) {
    if (!_isLoaded) {
      throw Exception('Bad words list not loaded. Call loadBadWords() first.');
    }

    final lowerText = text.toLowerCase();
    final foundWords = <String>[];
    
    for (final badWord in _badWords) {
      final pattern = RegExp(r'\b' + RegExp.escape(badWord) + r'\b');
      if (pattern.hasMatch(lowerText)) {
        foundWords.add(badWord);
      }
    }
    
    return foundWords;
  }

  /// Retourne le nombre total de mots interdits chargés
  int get badWordsCount => _badWords.length;
}
