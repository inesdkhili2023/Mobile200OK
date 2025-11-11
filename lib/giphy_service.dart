import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyService {
  static const String _apiKey = '92ZMNDKtXKzzB2ennKfS4gjzSPHFp3No';
  static const String _baseUrl = 'https://api.giphy.com/v1/gifs';
  
  // Search GIFs
  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?api_key=$_apiKey&q=$query&limit=$limit&rating=g&lang=fr'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gifs = data['data'];
        
        return gifs.map<Map<String, dynamic>>((gif) {
          return {
            'id': gif['id'],
            'title': gif['title'] ?? 'GIF',
            'url': gif['images']['original']['url'],
            'preview_url': gif['images']['fixed_width']['url'],
            'width': gif['images']['original']['width'],
            'height': gif['images']['original']['height'],
          };
        }).toList();
      } else {
        throw Exception('Erreur API GIPHY: ${response.statusCode}');
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
            'preview_url': gif['images']['fixed_width']['url'],
          };
        }).toList();
      } else {
        throw Exception('Erreur API GIPHY: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur GIFs tendance: $e');
      return [];
    }
  }
}