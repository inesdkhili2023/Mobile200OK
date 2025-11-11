import 'package:flutter/material.dart';
import '../models/user_service.dart';
import '../services/user_service_manager.dart';
import '../services/shared_prefs_service.dart';
import '../services/image_service.dart';
import 'create_service_screen.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final UserServiceManager _serviceManager = UserServiceManager();
  List<UserService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserServices();
  }

  Future<void> _loadUserServices() async {
    final serviceManager = UserServiceManager();
    await serviceManager.initUserServicesTable();
    
    final services = await serviceManager.getAllServices();
    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  void _editService(UserService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateServiceScreen(serviceToEdit: service),
      ),
    ).then((_) => _loadUserServices());
  }

  void _deleteService(UserService service) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce service ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _serviceManager.deleteUserService(service.id!);
              if (mounted) Navigator.pop(context);
              _loadUserServices();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service supprimé avec succès')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewServiceDetails(UserService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ServiceDetailsBottomSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les Services'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      // SUPPRIMÉ: FloatingActionButton
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? _buildEmptyState()
              : _buildServicesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun service disponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun service créé pour le moment',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ServiceCard(
          service: service,
          onEdit: () => _editService(service),
          onDelete: () => _deleteService(service),
          onTap: () => _viewServiceDetails(service),
        );
      },
    );
  }
}

class ServiceCard extends StatelessWidget {
  final UserService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getServiceIcon(service.category),
            color: const Color(0xFF6C5CE7),
          ),
        ),
        title: Text(
          service.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.category),
            const SizedBox(height: 4),
            Text(
              service.formattedPrice,
              style: TextStyle(
                color: const Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Par: ${service.userId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        // RÉTABLI: PopupMenuButton avec options Modifier et Supprimer
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getServiceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'Plumbing': return Icons.plumbing;
      case 'Electrician': return Icons.electrical_services;
      case 'Cleaning': return Icons.cleaning_services;
      case 'Carpenter': return Icons.carpenter;
      case 'Repairing': return Icons.build;
      default: return Icons.handyman;
    }
  }
}

class ServiceDetailsBottomSheet extends StatelessWidget {
  final UserService service;

  const ServiceDetailsBottomSheet({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            service.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Par: ${service.userId}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            service.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.category, 'Catégorie', service.category),
          _buildDetailRow(Icons.attach_money, 'Prix', service.formattedPrice),
          _buildDetailRow(Icons.location_on, 'Localisation', service.location),
          _buildDetailRow(Icons.calendar_today, 'Créé le', 
            '${service.createdAt.day}/${service.createdAt.month}/${service.createdAt.year}'),
          
          if (service.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Images:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: service.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ImageService.buildImage(
                        service.images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}