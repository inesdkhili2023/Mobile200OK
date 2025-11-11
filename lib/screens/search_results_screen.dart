import 'package:flutter/material.dart';
import 'package:service_app/models/worker_model.dart';
import 'package:service_app/models/user_service.dart';
import 'package:service_app/screens/category_screen.dart';
import 'package:service_app/screens/worker_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;
  final List<WorkerModel> workers;
  final List<UserService> services;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.workers,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    final totalResults = workers.length + services.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats pour "$searchQuery"'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$totalResults résultat(s) trouvé(s)',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF6C5CE7),
                      unselectedLabelColor: const Color(0xFF666666),
                      indicatorColor: const Color(0xFF6C5CE7),
                      tabs: [
                        Tab(text: 'Prestataires (${workers.length})'),
                        Tab(text: 'Services (${services.length})'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Onglet Prestataires
                        workers.isEmpty
                            ? _buildEmptyState('Aucun prestataire trouvé')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: workers.length,
                                itemBuilder: (context, index) {
                                  final worker = workers[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFF0EBFF), // Remplacement de withOpacity(0.1)
                                        child: const Icon(Icons.person, color: Color(0xFF6C5CE7)),
                                      ),
                                      title: Text(worker.fullName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(worker.workType),
                                          Text('${worker.price} DT/heure'),
                                        ],
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WorkerDetailScreen(worker: worker),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                        
                        // Onglet Services
                        services.isEmpty
                            ? _buildEmptyState('Aucun service trouvé')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: services.length,
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFF0EBFF), // Remplacement de withOpacity(0.1)
                                        child: const Icon(Icons.work, color: Color(0xFF6C5CE7)),
                                      ),
                                      title: Text(service.title),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(service.category),
                                          Text(service.formattedPrice),
                                        ],
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CategoryScreen(categoryName: service.category),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}