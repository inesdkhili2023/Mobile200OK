import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_app/models/worker_model.dart';
import 'package:service_app/models/user_service.dart';
import 'package:service_app/services/database_helper.dart';
import 'package:service_app/services/user_service_manager.dart';
import 'package:service_app/services/shared_prefs_service.dart';
import 'package:service_app/screens/registration_success_screen.dart';

class BecomeWorkerScreen extends StatefulWidget {
  const BecomeWorkerScreen({super.key});

  @override
  State<BecomeWorkerScreen> createState() => _BecomeWorkerScreenState();
}

class _BecomeWorkerScreenState extends State<BecomeWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serviceTitleController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  
  String? selectedWorkType;
  String? profileImagePath;
  List<String> portfolioImages = [];
  final ImagePicker _picker = ImagePicker();

  // Variables pour la localisation
  String? _currentAddress;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _showLocationMap = false;

  final List<Map<String, dynamic>> workTypes = [
    {'name': 'Plumbing', 'icon': Icons.plumbing, 'selected': false},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'selected': false},
    {'name': 'Carpenter', 'icon': Icons.carpenter, 'selected': false},
    {'name': 'Electrician', 'icon': Icons.electrical_services, 'selected': false},
    {'name': 'Repairing', 'icon': Icons.build, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _serviceTitleController.dispose();
    _serviceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showErrorSnackBar('Les permissions de localisation sont refusées');
          }
          _setLoadingFalse();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorSnackBar('Les permissions de localisation sont définitivement refusées. Activez-les dans les paramètres de l\'appareil.');
        }
        _setLoadingFalse();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _showLocationMap = true;
        });
      }

      await _getAddressFromLatLng(position);
      
    } catch (e) {
      debugPrint('Erreur de localisation: $e');
      _setLoadingFalse();
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la récupération de la localisation: $e');
        
        // Position par défaut (Tunis)
        setState(() {
          _selectedLocation = const LatLng(36.8065, 10.1815); // Tunis
          _showLocationMap = true;
          _currentAddress = "Tunis, Tunisie";
        });
      }
    }
  }

  void _setLoadingFalse() {
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      String address = await _simpleGeocoding(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint("Erreur géocodage: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Position: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  Future<String> _simpleGeocoding(double lat, double lng) async {
    if (lat >= 36.7 && lat <= 37.0 && lng >= 10.0 && lng <= 10.3) {
      return "Tunis, Tunisie";
    } else if (lat >= 34.0 && lat <= 37.0 && lng >= 8.0 && lng <= 11.0) {
      return "Nord de la Tunisie";
    } else if (lat >= 32.0 && lat <= 34.0 && lng >= 9.0 && lng <= 11.0) {
      return "Centre de la Tunisie";
    } else if (lat >= 30.0 && lat <= 32.0 && lng >= 8.0 && lng <= 11.0) {
      return "Sud de la Tunisie";
    } else {
      return "Position: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          profileImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sélection de l\'image');
      }
    }
  }

  Future<void> _pickPortfolioImage() async {
    if (portfolioImages.length >= 5) {
      if (mounted) {
        _showWarningSnackBar('Maximum 5 images de portfolio autorisées');
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          portfolioImages.add(image.path);
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection image portfolio: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sélection de l\'image');
      }
    }
  }

  void _removePortfolioImage(int index) {
    if (mounted) {
      setState(() {
        portfolioImages.removeAt(index);
      });
    }
  }

  void _showLocationPicker() {
    if (_selectedLocation == null) {
      _getCurrentLocation();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerBottomSheet(
        initialLocation: _selectedLocation!,
        onLocationSelected: (LatLng location) async {
          if (mounted) {
            setState(() {
              _selectedLocation = location;
              _showLocationMap = true;
            });
          }
          await _getAddressFromLatLng(Position(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ));
        },
      ),
    );
  }

  Future<void> _submitForm() async {
  if (_isSubmitting) return;
  
  if (!_formKey.currentState!.validate()) {
    _showErrorSnackBar('Veuillez corriger les erreurs dans le formulaire');
    return;
  }

  if (selectedWorkType == null) {
    _showErrorSnackBar('Veuillez sélectionner un type de service');
    return;
  }

  if (_selectedLocation == null) {
    _showErrorSnackBar('Veuillez sélectionner une localisation');
    return;
  }

  if (mounted) {
    setState(() {
      _isSubmitting = true;
    });
  }

  try {
    final worker = WorkerModel(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      workType: selectedWorkType!,
      yearsOfExperience: int.parse(_experienceController.text),
      price: int.parse(_priceController.text.isEmpty ? '80' : _priceController.text),
      rating: 0.0,
      profileImage: profileImagePath,
      portfolioImages: portfolioImages.isNotEmpty ? portfolioImages : null,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      address: _currentAddress,
    );

    final db = DatabaseHelper.instance;
    await db.insertWorker(worker);

    final serviceManager = UserServiceManager();
    
    // ✅ INITIALISER LA TABLE AVANT D'AJOUTER LE SERVICE
    await serviceManager.initUserServicesTable();
    
    final service = UserService.create(
      userId: _fullNameController.text.trim(),
      title: _serviceTitleController.text.isEmpty 
          ? "Service de $selectedWorkType" 
          : _serviceTitleController.text.trim(),
      description: _serviceDescriptionController.text.isEmpty
          ? "Service professionnel de $selectedWorkType proposé par ${_fullNameController.text.trim()}"
          : _serviceDescriptionController.text.trim(),
      category: selectedWorkType!,
      price: double.parse(_priceController.text.isEmpty ? '80' : _priceController.text),
      priceType: 'hourly',
      images: portfolioImages,
      location: _currentAddress ?? 'Localisation non spécifiée',
    );

    await serviceManager.addUserService(service);

    await SharedPrefsService.addNotification(
      'Vous êtes maintenant enregistré en tant que $selectedWorkType! Votre service a été créé automatiquement.'
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationSuccessScreen(),
        ),
      );
    }
  } catch (e) {
    debugPrint('Erreur soumission formulaire: $e');
    if (mounted) {
      _showErrorSnackBar('Erreur lors de la soumission: $e');
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
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
        title: const Text(
          'Devenir Prestataire',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6C5CE7),
                            width: 3,
                          ),
                        ),
                        child: profileImagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(profileImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez pour ajouter une photo de profil',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _fullNameController,
                label: 'Nom Complet *',
                hint: 'Entrez votre nom complet',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom complet';
                  }
                  if (value.length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Numéro de Téléphone *',
                hint: 'Entrez votre numéro de téléphone',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  if (!RegExp(r'^[0-9+\-\s]{8,}$').hasMatch(value)) {
                    return 'Veuillez entrer un numéro valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Adresse Email *',
                hint: 'Entrez votre adresse email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildWorkTypeField(),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _experienceController,
                label: "Années d'Expérience *",
                hint: "Entrez vos années d'expérience",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer vos années d'expérience";
                  }
                  final years = int.tryParse(value);
                  if (years == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (years < 0 || years > 50) {
                    return 'Veuillez entrer un nombre entre 0 et 50';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _priceController,
                label: 'Tarif Horaire (DT) *',
                hint: 'Entrez votre tarif horaire',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre tarif horaire';
                  }
                  final price = int.tryParse(value);
                  if (price == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (price <= 0) {
                    return 'Le tarif doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Section Service
              const Text(
                'Informations du Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _serviceTitleController,
                label: 'Titre du Service',
                hint: 'Ex: Réparation de plomberie professionnelle',
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _serviceDescriptionController,
                label: 'Description du Service',
                hint: 'Décrivez votre service en détail...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'À propos de vous',
                hint: 'Parlez de vos compétences et expériences',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // Localisation Section
              const Text(
                'Localisation *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildLocationField(),
              const SizedBox(height: 24),
              
              // Portfolio Section
              const Text(
                'Portfolio (Optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              if (portfolioImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: portfolioImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(portfolioImages[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removePortfolioImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 8),
              
              OutlinedButton.icon(
                onPressed: _pickPortfolioImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Ajouter des Images Portfolio (${portfolioImages.length}/5)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF6C5CE7)),
                  foregroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Soumettre la Demande',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _selectedLocation != null 
                      ? const Color(0xFF6C5CE7) 
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingLocation
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Chargement de la localisation...'),
                          ],
                        )
                      : _currentAddress != null
                          ? Text(
                              _currentAddress!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : const Text(
                              'Cliquez pour sélectionner votre localisation',
                              style: TextStyle(color: Colors.grey),
                            ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
            if (_showLocationMap && _selectedLocation != null) ...[
              const SizedBox(height: 12),
              Text(
                'Cliquez sur la carte pour changer la localisation',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _selectedLocation!,
                      initialZoom: 14,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                        _getAddressFromLatLng(Position(
                          latitude: point.latitude,
                          longitude: point.longitude,
                          timestamp: DateTime.now(),
                          accuracy: 0,
                          altitude: 0,
                          heading: 0,
                          speed: 0,
                          speedAccuracy: 0,
                          altitudeAccuracy: 0,
                          headingAccuracy: 0,
                        ));
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.serviceapp',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFF6C5CE7),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedLocation == null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_searching),
                label: const Text('Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de Service *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showWorkTypeDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedWorkType ?? 'Sélectionnez un type de service',
                  style: TextStyle(
                    color: selectedWorkType == null ? Colors.grey[400] : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (selectedWorkType == null) ...[
          const SizedBox(height: 4),
          Text(
            'Ce champ est obligatoire',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  void _showWorkTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sélectionnez le Type de Service',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...workTypes.map((type) => _buildWorkTypeOption(type)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkTypeOption(Map<String, dynamic> type) {
    final isSelected = selectedWorkType == type['name'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWorkType = type['name'];
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              type['icon'],
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6C5CE7),
              ),
          ],
        ),
      ),
    );
  }
}

class LocationPickerBottomSheet extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerBottomSheet({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  late MapController _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_selectedLocation!, 14);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text(
            'Sélectionnez votre localisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation,
                  initialZoom: 14,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.serviceapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFF6C5CE7),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedLocation != null) {
                      widget.onLocationSelected(_selectedLocation!);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}