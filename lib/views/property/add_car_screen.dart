import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/car_service.dart';
import '../../services/location_service.dart';
import '../../models/car_model.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import '../../utils/constants.dart';

class AddCarScreen extends StatefulWidget {
  final CarModel? car;
  const AddCarScreen({super.key, this.car});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _seatsController;
  late final TextEditingController _fuelCapacityController;
  late final TextEditingController _mileageController;
  
  late CarType _selectedCarType;
  late FuelType _selectedFuelType;
  String? _selectedCity;
  String? _selectedNeighborhood;
  List<LocationModel> _locations = [];
  List<String> _availableNeighborhoods = [];
  bool _isLoading = false;
  final List<XFile> _images = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedFeatures = [];

  final List<String> _availableFeatures = [
    'Air Conditioning',
    'Power Steering',
    'ABS Brakes',
    'Sunroof',
    'Leather Seats',
    'Automatic Transmission',
    'Power Windows',
    'Cruise Control',
    'Bluetooth',
    'USB Charging',
    'Rear Camera',
    '4WD',
  ];

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.car?.make);
    _modelController = TextEditingController(text: widget.car?.model);
    _yearController = TextEditingController(text: widget.car?.year);
    _colorController = TextEditingController(text: widget.car?.color);
    _descriptionController = TextEditingController(text: widget.car?.description);
    _priceController = TextEditingController(text: widget.car?.pricePerDay.toString());
    _seatsController = TextEditingController(text: widget.car?.seats.toString());
    _fuelCapacityController = TextEditingController(text: widget.car?.fuelCapacity.toString());
    _mileageController = TextEditingController(text: widget.car?.mileage.toString());
    _selectedCarType = widget.car?.carType ?? CarType.sedan;
    _selectedFuelType = widget.car?.fuelType ?? FuelType.petrol;
    _selectedCity = widget.car?.city;
    _selectedNeighborhood = widget.car?.neighborhood;
    if (widget.car != null) {
      _existingImageUrls.addAll(widget.car!.imageUrls);
      _selectedFeatures.addAll(widget.car!.features);
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
      if (index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      } else {
        _images.removeAt(index - _existingImageUrls.length);
      }
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

        final carService = context.read<CarService>();
        List<String> imageUrls = List.from(_existingImageUrls);

        for (var image in _images) {
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          String path = 'cars/${user.uid}/$fileName';
          String url = await carService.uploadImage(image, path);
          imageUrls.add(url);
        }

        final car = CarModel(
          id: widget.car?.id ?? '',
          ownerId: user.uid,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: _yearController.text.trim(),
          color: _colorController.text.trim(),
          pricePerDay: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          seats: int.parse(_seatsController.text),
          fuelCapacity: int.parse(_fuelCapacityController.text),
          fuelType: _selectedFuelType,
          carType: _selectedCarType,
          mileage: int.parse(_mileageController.text),
          imageUrls: imageUrls,
          features: _selectedFeatures,
          city: _selectedCity!,
          neighborhood: _selectedNeighborhood ?? '',
          isApproved: false,
          createdAt: widget.car?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.car != null) {
          await carService.updateCar(widget.car!.id, car.toMap());
        } else {
          await carService.addCar(car);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.car != null ? 'Car updated successfully!' : 'Car listed successfully!')),
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
                  'Only car owners and agents can list cars for hire.',
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
        title: Text(widget.car != null ? 'Edit Car Listing' : 'List a Car for Hire'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Car Photos'),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Basic Information'),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _makeController,
                        label: 'Make',
                        hint: 'Toyota, Honda, etc',
                        icon: Icons.directions_car_rounded,
                        validator: (v) => v!.isEmpty ? 'Make is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _modelController,
                        label: 'Model',
                        hint: 'e.g. Camry',
                        icon: Icons.directions_car_rounded,
                        validator: (v) => v!.isEmpty ? 'Model is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Tell potential renters about your car...',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Description is required' : null,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Vehicle Details'),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        hint: '2023',
                        icon: Icons.calendar_today_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _colorController,
                        label: 'Color',
                        hint: 'e.g. Black',
                        icon: Icons.format_color_fill_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _mileageController,
                  label: 'Mileage (km)',
                  hint: '50000',
                  icon: Icons.speed_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Rental & Specifications'),
              _buildCard([
                _buildTextField(
                  controller: _priceController,
                  label: 'Price per Day (KSh)',
                  hint: 'e.g. 5000',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Price is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _seatsController,
                        label: 'Seats',
                        hint: '5',
                        icon: Icons.event_seat_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _fuelCapacityController,
                        label: 'Fuel Tank (L)',
                        hint: '60',
                        icon: Icons.local_gas_station_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Car Type'),
              _buildCard([_buildCarTypeSelector()]),
              const SizedBox(height: 24),
              _buildSectionHeader('Fuel Type'),
              _buildCard([_buildFuelTypeSelector()]),
              const SizedBox(height: 24),
              _buildSectionHeader('Location'),
              _buildCard([
                _buildCityDropdown(),
                const SizedBox(height: 16),
                _buildNeighborhoodDropdown(),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader('Features'),
              _buildCard([
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableFeatures.map((feature) {
                    final isSelected = _selectedFeatures.contains(feature);
                    return FilterChip(
                      label: Text(feature),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFeatures.add(feature);
                          } else {
                            _selectedFeatures.remove(feature);
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
                        widget.car != null ? 'Update Listing' : 'List Car',
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

  Widget _buildCarTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Car Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CarType.values.map((type) {
            final isSelected = _selectedCarType == type;
            IconData icon;
            String label;

            switch (type) {
              case CarType.sedan:
                icon = Icons.directions_car_rounded;
                label = 'Sedan';
                break;
              case CarType.suv:
                icon = Icons.directions_car_rounded;
                label = 'SUV';
                break;
              case CarType.van:
                icon = Icons.local_shipping_rounded;
                label = 'Van';
                break;
              case CarType.hatchback:
                icon = Icons.directions_car_rounded;
                label = 'Hatchback';
                break;
              case CarType.convertible:
                icon = Icons.directions_car_rounded;
                label = 'Convertible';
                break;
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedCarType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: isSelected ? AppConstants.primaryColor : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFuelTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fuel Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FuelType.values.map((type) {
            final isSelected = _selectedFuelType == type;
            IconData icon;
            String label;

            switch (type) {
              case FuelType.petrol:
                icon = Icons.local_gas_station_rounded;
                label = 'Petrol';
                break;
              case FuelType.diesel:
                icon = Icons.local_gas_station_rounded;
                label = 'Diesel';
                break;
              case FuelType.electric:
                icon = Icons.electric_car_rounded;
                label = 'Electric';
                break;
              case FuelType.hybrid:
                icon = Icons.nature_rounded;
                label = 'Hybrid';
                break;
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedFuelType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: isSelected ? AppConstants.primaryColor : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _existingImageUrls[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
                      ),
                    );
                  }

                  final newImageIndex = index - _existingImageUrls.length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_images[newImageIndex].path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    ]);
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _fuelCapacityController.dispose();
    _mileageController.dispose();
    super.dispose();
  }
}
