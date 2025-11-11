import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyService {
  static const String _apiKey = '92ZMNDKtXKzzB2ennKfS4gjzSPHFp3No';
  static const String _baseUrl = 'https://api.giphy.com/v1/gifs';
  
  // Search GIFs
  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
    try {
      if (query.trim().isEmpty) {
        return await getTrendingGifs(limit: limit);
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/search?api_key=$_apiKey&q=${Uri.encodeQueryComponent(query)}&limit=$limit&rating=g&lang=fr'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gifs = data['data'];
        
        return gifs.map<Map<String, dynamic>>((gif) {
          return {
            'id': gif['id'],
            'title': gif['title'] ?? 'GIF',
            'url': gif['images']['original']['url'],
            'preview_url': gif['images']['fixed_width']['url'] ?? gif['images']['original']['url'],
            'width': double.tryParse(gif['images']['original']['width']?.toString() ?? '200') ?? 200.0,
            'height': double.tryParse(gif['images']['original']['height']?.toString() ?? '200') ?? 200.0,
            'size': gif['images']['original']['size'], // Taille du fichier
          };
        }).toList();
      } else {
        print('❌ Erreur API GIPHY: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur recherche GIFs: $e');
      return [];
    }
  }
  
  // Trending GIFs
  static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 25}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending?api_key=$_apiKey&limit=$limit&rating=g'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gifs = data['data'];
        
        return gifs.map<Map<String, dynamic>>((gif) {
          return {
            'id': gif['id'],
            'title': gif['title'] ?? 'GIF tendance',
            'url': gif['images']['original']['url'],
            'preview_url': gif['images']['fixed_width']['url'] ?? gif['images']['original']['url'],
            'width': double.tryParse(gif['images']['original']['width']?.toString() ?? '200') ?? 200.0,
            'height': double.tryParse(gif['images']['original']['height']?.toString() ?? '200') ?? 200.0,
          };
        }).toList();
      } else {
        print('❌ Erreur API GIPHY: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur GIFs tendance: $e');
      return [];
    }
  }
  
  // 🆕 Méthode pour obtenir des GIFs aléatoires
  static Future<List<Map<String, dynamic>>> getRandomGifs({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending?api_key=$_apiKey&limit=$limit&rating=g'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gifs = data['data'];
        
        // Mélanger les résultats pour un effet "aléatoire"
        gifs.shuffle();
        
        return gifs.take(limit).map<Map<String, dynamic>>((gif) {
          return {
            'id': gif['id'],
            'title': gif['title'] ?? 'GIF aléatoire',
            'url': gif['images']['original']['url'],
            'preview_url': gif['images']['fixed_width']['url'] ?? gif['images']['original']['url'],
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Erreur GIFs aléatoires: $e');
      return [];
    }
  }
}