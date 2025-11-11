import 'package:flutter/material.dart';
import 'package:service_app/services/shared_prefs_service.dart';
import 'package:service_app/services/database_helper.dart';
import 'package:service_app/services/user_service_manager.dart';
import 'package:service_app/models/worker_model.dart';
import 'package:service_app/models/user_service.dart';
import 'package:service_app/screens/category_screen.dart';
import 'package:service_app/screens/search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];
  List<String> searchSuggestions = [];
  bool _showSuggestions = false;
  
  final List<String> popularServices = [
    'Plomberie',
    'Électricité',
    'Nettoyage',
    'Menuiserie',
    'Peinture',
    'Réparation',
    'Plumbing',
    'Electrician',
    'Cleaning',
    'Carpenter',
    'Painting',
    'Repairing'
  ];

  // Liste de toutes les catégories disponibles
  final List<String> allCategories = [
    'Plomberie', 'Électricité', 'Nettoyage', 'Menuiserie', 'Peinture', 'Réparation',
    'Plumbing', 'Electrician', 'Cleaning', 'Carpenter', 'Painting', 'Repairing'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        searchSuggestions = [];
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      // Générer des suggestions basées sur la recherche
      searchSuggestions = _generateSearchSuggestions(query);
    });
  }

  List<String> _generateSearchSuggestions(String query) {
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();

    // Suggestions de catégories
    for (final category in allCategories) {
      if (category.toLowerCase().contains(lowerQuery) &&
          !suggestions.contains(category)) {
        suggestions.add(category);
      }
    }

    // Suggestions de services populaires
    for (final service in popularServices) {
      if (service.toLowerCase().contains(lowerQuery) &&
          !suggestions.contains(service) &&
          suggestions.length < 10) {
        suggestions.add(service);
      }
    }

    return suggestions.take(8).toList(); // Limiter à 8 suggestions
  }

  void _loadRecentSearches() {
    setState(() {
      recentSearches = SharedPrefsService.getRecentSearches();
    });
  }

  void _performSearch(String search) async {
    if (search.trim().isEmpty) return;

    final query = search.trim();
    
    // Sauvegarder la recherche récente
    SharedPrefsService.addRecentSearch(query);
    _loadRecentSearches();

    // Rechercher dans les workers et services
    final db = DatabaseHelper.instance;
    final serviceManager = UserServiceManager();
    
    try {
      // Recherche dans les workers
      final workers = await db.searchWorkers(query);
      
      // Recherche dans les services
      await serviceManager.initUserServicesTable();
      final services = await serviceManager.searchServices(query);

      // Naviguer vers l'écran des résultats
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsScreen(
              searchQuery: query,
              workers: workers,
              services: services,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      // Fallback: naviguer vers la catégorie si la recherche échoue
      _navigateToCategory(query);
    }
  }

  void _navigateToCategory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryScreen(categoryName: categoryName),
      ),
    );
  }

  void _clearAllSearches() {
    SharedPrefsService.clearRecentSearches();
    setState(() {
      recentSearches = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historique de recherche effacé'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeSearch(String search) {
    setState(() {
      recentSearches.remove(search);
    });
    SharedPrefsService.clearRecentSearches();
    for (var s in recentSearches) {
      SharedPrefsService.addRecentSearch(s);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher un service...',
              hintStyle: const TextStyle(color: Color(0xFF888888)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              _performSearch(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF6C5CE7)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Options de filtrage à venir')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestions de recherche
          if (_showSuggestions && searchSuggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  ...searchSuggestions.map((suggestion) => ListTile(
                    leading: const Icon(Icons.search, color: Color(0xFF666666)),
                    title: Text(suggestion),
                    onTap: () {
                      _searchController.text = suggestion;
                      _performSearch(suggestion);
                    },
                  )),
                  const Divider(height: 1),
                ],
              ),
            ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recherches récentes
                  if (!_showSuggestions) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recherches récentes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (recentSearches.isNotEmpty)
                            TextButton(
                              onPressed: _clearAllSearches,
                              child: const Text(
                                'Tout effacer',
                                style: TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (recentSearches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 60,
                                color: Color(0xFFCCCCCC),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucune recherche récente',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          final search = recentSearches[index];
                          return ListTile(
                            leading: const Icon(Icons.history, color: Color(0xFF666666)),
                            title: Text(search),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF666666)),
                              onPressed: () => _removeSearch(search),
                            ),
                            onTap: () {
                              _searchController.text = search;
                              _performSearch(search);
                            },
                          );
                        },
                      ),
                    const Divider(height: 32),
                  ],
                  
                  // Services populaires
                  if (!_showSuggestions) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Services populaires',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: popularServices.map((service) {
                              return GestureDetector(
                                onTap: () => _performSearch(service),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFDDDDDD),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: const Color(0xFF666666),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        service,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}