import 'package:flutter/material.dart';
import '../models/user_service.dart';
import '../services/user_service_manager.dart';
import '../services/shared_prefs_service.dart';
import '../widgets/portfolio_widget.dart';

class CreateServiceScreen extends StatefulWidget {
  final UserService? serviceToEdit;

  const CreateServiceScreen({super.key, this.serviceToEdit});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _userController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedPriceType;
  List<String> _images = [];
  
  final List<String> _categories = [
    'Plumbing', 'Electrician', 'Cleaning', 
    'Carpenter', 'Repairing'
  ];
  
  final List<String> _priceTypes = ['hourly', 'fixed', 'negotiable'];

  @override
  void initState() {
    super.initState();
    if (widget.serviceToEdit != null) {
      _loadServiceData();
    } else {
      // Pour un nouveau service, on peut mettre une valeur par défaut
      _userController.text = 'Utilisateur Anonyme';
    }
  }

  void _loadServiceData() {
    final service = widget.serviceToEdit!;
    _titleController.text = service.title;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toString();
    _locationController.text = service.location;
    _userController.text = service.userId;
    _selectedCategory = service.category;
    _selectedPriceType = service.priceType;
    _images = List.from(service.images);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && 
        _selectedCategory != null && 
        _selectedPriceType != null) {
      
      final userId = _userController.text.isNotEmpty 
          ? _userController.text 
          : 'Utilisateur Anonyme';

      final service = UserService.create(
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        priceType: _selectedPriceType!,
        images: _images,
        location: _locationController.text,
      );

      final serviceManager = UserServiceManager();
      
      try {
        if (widget.serviceToEdit != null) {
          // Modification
          final updatedService = widget.serviceToEdit!.copyWith(
            title: service.title,
            description: service.description,
            category: service.category,
            price: service.price,
            priceType: service.priceType,
            images: service.images,
            location: service.location,
            userId: userId,
            updatedAt: DateTime.now(),
          );
          await serviceManager.updateUserService(updatedService);
        } else {
          // Création
          await serviceManager.addUserService(service);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.serviceToEdit != null 
                  ? 'Service modifié avec succès' 
                  : 'Service créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceToEdit != null ? 'Modifier le Service' : 'Créer un Service'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Titre du Service *',
                hint: 'Ex: Réparation de robinet',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Décrivez votre service en détail...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _userController,
                label: 'Nom du Prestataire *',
                hint: 'Votre nom ou nom de l\'entreprise',
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _selectedCategory,
                items: _categories,
                label: 'Catégorie *',
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _selectedPriceType,
                items: _priceTypes,
                label: 'Type de Prix *',
                onChanged: (value) => setState(() => _selectedPriceType = value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Prix *',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Localisation *',
                hint: 'Ville ou région',
              ),
              const SizedBox(height: 24),
              PortfolioWidget(
                initialImages: _images,
                onImagesChanged: (images) => setState(() => _images = images),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.serviceToEdit != null ? 'Modifier le Service' : 'Créer le Service',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(_formatPriceType(item)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une option';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _formatPriceType(String type) {
    switch (type) {
      case 'hourly': return 'À l\'heure';
      case 'fixed': return 'Prix fixe';
      case 'negotiable': return 'Négociable';
      default: return type;
    }
  }
}