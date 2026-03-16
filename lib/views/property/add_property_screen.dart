import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/property_service.dart';
import '../../services/location_service.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import '../../utils/constants.dart';

class AddPropertyScreen extends StatefulWidget {
  final PropertyModel? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late PropertyType _selectedType;
  String? _selectedCity;
  String? _selectedNeighborhood;
  List<LocationModel> _locations = [];
  List<String> _availableNeighborhoods = [];
  bool _isLoading = false;
  final List<XFile> _images = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property?.title);
    _descriptionController = TextEditingController(text: widget.property?.description);
    _priceController = TextEditingController(text: widget.property?.price.toString());
    _neighborhoodController = TextEditingController(text: widget.property?.neighborhood);
    _bedroomsController = TextEditingController(text: widget.property?.bedrooms.toString());
    _bathroomsController = TextEditingController(text: widget.property?.bathrooms.toString());
    _selectedType = widget.property?.type ?? PropertyType.rental;
    _selectedCity = widget.property?.city;
    _selectedNeighborhood = widget.property?.neighborhood;
    if (widget.property != null) {
      _existingImageUrls.addAll(widget.property!.imageUrls);
      _selectedAmenities.addAll(widget.property!.amenities);
    }
    _loadLocations();
  }

  void _loadLocations() {
    context.read<LocationService>().getActiveLocations().first.then((locations) {
      if (mounted) {
        setState(() {
          _locations = locations;
          if (_selectedCity != null) {
            final city = _locations.firstWhere(
              (l) => l.name == _selectedCity,
              orElse: () => LocationModel(id: '', name: '', neighborhoods: []),
            );
            _availableNeighborhoods = city.neighborhoods;
          }
        });
      }
    });
  }

  final List<String> _availableAmenities = [
    'WiFi',
    'Parking',
    'Swimming Pool',
    'Gym',
    'Air Conditioning',
    'Security 24/7',
    'Borehole',
    'Elevator',
    'Balcony',
    'Pet Friendly',
    'Furnished',
    'CCTV',
    'Clean Water',
    'Roads',
    'Electricity',
    'Schools',
  ];

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty && _existingImageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one photo'), backgroundColor: Colors.orange),
        );
        return;
      }
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a city'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not logged in');

        final propertyService = context.read<PropertyService>();
        List<String> imageUrls = List.from(_existingImageUrls);

        for (var image in _images) {
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          String path = 'properties/${user.uid}/$fileName';
          String url = await propertyService.uploadImage(image, path);
          imageUrls.add(url);
        }

        final property = PropertyModel(
          id: widget.property?.id ?? '',
          landlordId: user.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          city: _selectedCity!,
          neighborhood: _selectedNeighborhood ?? '',
          type: _selectedType,
          imageUrls: imageUrls,
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          amenities: _selectedAmenities,
          isApproved: false, // Reset approval status on any change
          createdAt: widget.property?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.property != null) {
          await propertyService.updateProperty(widget.property!.id, property.toMap());
        } else {
          await propertyService.addProperty(property);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.property != null ? 'Property updated successfully!' : 'Property listed successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppConstants.errorColor),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();

    if (userModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userModel.role == UserRole.tenant) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Only landlords and agents can post or edit properties.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(widget.property != null ? 'Edit Property' : 'List a Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Property Photos'),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Basic Information'),
              _buildCard([
                _buildTextField(
                  controller: _titleController,
                  label: 'Property Title',
                  hint: 'e.g. Modern Apartment in Kilimani',
                  icon: Icons.title_rounded,
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Tell potential tenants about your property...',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                _buildPropertyTypeSelector(),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Pricing & Specifications'),
              _buildCard([
                _buildTextField(
                  controller: _priceController,
                  label: 'Price per Month (KSh)',
                  hint: 'e.g. 45000',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Price is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _bedroomsController,
                        label: 'Bedrooms',
                        hint: '0',
                        icon: Icons.bed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _bathroomsController,
                        label: 'Bathrooms',
                        hint: '0',
                        icon: Icons.bathtub_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Location Details'),
              _buildCard([
                _buildCityDropdown(),
                const SizedBox(height: 16),
                _buildNeighborhoodDropdown(),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Amenities'),
              _buildCard([
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? AppConstants.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.property != null ? 'Update Listing' : 'Post Listing',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildCard([
      if (_images.isEmpty && _existingImageUrls.isEmpty)
        Center(
          child: Column(
            children: [
              const Icon(Icons.add_a_photo_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImages,
                child: const Text('Add Photos'),
              ),
            ],
          ),
        )
      else
        Column(
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length + _images.length + 1,
                itemBuilder: (context, index) {
                  if (index == _existingImageUrls.length + _images.length) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add_rounded, size: 32, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  if (index < _existingImageUrls.length) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_existingImageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final newImageIndex = index - _existingImageUrls.length;
                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_images[newImageIndex].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeImage(newImageIndex),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    ]);
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          items: _locations.map((location) {
            return DropdownMenuItem(
              value: location.name,
              child: Text(location.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              final city = _locations.firstWhere((l) => l.name == value);
              _availableNeighborhoods = city.neighborhoods;
              _selectedNeighborhood = null;
            });
          },
          decoration: InputDecoration(
            hintText: 'Select City',
            prefixIcon: const Icon(Icons.location_city_rounded, color: AppConstants.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
          ),
          validator: (v) => v == null ? 'City is required' : null,
        ),
      ],
    );
  }

  Widget _buildNeighborhoodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Neighborhood / Area',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedNeighborhood,
          items: _availableNeighborhoods.map((area) {
            return DropdownMenuItem(
              value: area,
              child: Text(area),
            );
          }).toList(),
          onChanged: _selectedCity == null
              ? null
              : (value) {
                  setState(() {
                    _selectedNeighborhood = value;
                  });
                },
          decoration: InputDecoration(
            hintText: _selectedCity == null ? 'Select a city first' : 'Select Neighborhood',
            prefixIcon: const Icon(Icons.map_rounded, color: AppConstants.primaryColor, size: 20),
            filled: true,
            fillColor: _selectedCity == null ? Colors.grey.shade100 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
          ),
          validator: (v) => v == null ? 'Neighborhood is required' : null,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppConstants.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listing Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(
          children: PropertyType.values.map((type) {
            final isSelected = _selectedType == type;
            IconData icon;
            String label;
            
            switch (type) {
              case PropertyType.rental:
                icon = Icons.home_rounded;
                label = 'Long Term';
                break;
              case PropertyType.airbnb:
                icon = Icons.apartment_rounded;
                label = 'Airbnb';
                break;
              case PropertyType.onSale:
                icon = Icons.sell_rounded;
                label = 'On Sale';
                break;
              case PropertyType.bedsitter:
                icon = Icons.bed_rounded;
                label = 'Bedsitter';
                break;
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  margin: EdgeInsets.only(
                    right: type != PropertyType.values.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppConstants.primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
