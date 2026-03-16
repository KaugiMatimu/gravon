import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/property_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/property_model.dart';
import '../../models/location_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../widgets/property_card.dart';
import '../../widgets/user_avatar_menu.dart';
import '../../widgets/error_state_widget.dart';
import '../property/property_details_screen.dart';
import '../property/add_property_screen.dart';
import '../auth/login_screen.dart';

class PropertySearchView extends StatefulWidget {
  const PropertySearchView({super.key});

  @override
  State<PropertySearchView> createState() => _PropertySearchViewState();
}

class _PropertySearchViewState extends State<PropertySearchView> {
  String _searchQuery = '';
  String? _selectedCity;
  PropertyType? _selectedType;
  RangeValues _priceRange = const RangeValues(0, 500000);
  String _sortBy = 'createdAt';
  Stream<List<PropertyModel>?>? _propertiesStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream immediately
    _propertiesStream = context.read<PropertyService>().getProperties(
          sortBy: _sortBy,
        );
  }

  void _refreshProperties() {
    setState(() {
      _propertiesStream = context.read<PropertyService>().getProperties(
            sortBy: _sortBy,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.read<LocationService>();
    final currentUser = context.watch<firebase_auth.User?>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          // NAVBAR
          Container(
            color: AppConstants.darkBlue,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'transparent-logo.png',
                            height: 24,
                          ),
                        ),
                        const Spacer(),
                        // Nav links (hide on small screens)
                        if (constraints.maxWidth > 700)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Home',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                'Properties',
                                style: GoogleFonts.montserrat(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                        // User action
                        _buildUserAction(context, currentUser),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPropertyScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'List',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Search and filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Modern Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by city, name or description...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppConstants.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppConstants.primaryColor,
                      ),
                      onPressed: () => _showFilterSheet(context),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 16),

                // Dynamic Locations
                StreamBuilder<List<LocationModel>>(
                  stream: locationService.getActiveLocations(),
                  builder: (context, snapshot) {
                    final locations = snapshot.data ?? [];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Cities',
                            isSelected: _selectedCity == null,
                            onSelected: (val) =>
                                setState(() => _selectedCity = null),
                          ),
                          ...locations.map(
                            (loc) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _buildFilterChip(
                                label: loc.name,
                                isSelected: _selectedCity == loc.name,
                                onSelected: (val) => setState(
                                  () => _selectedCity = val ? loc.name : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<PropertyModel>?>(
              stream: _propertiesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    error: snapshot.error!,
                    onRetry: _refreshProperties,
                  );
                }
                var properties = snapshot.data ?? [];

                if (_propertiesStream == null ||
                    (snapshot.connectionState == ConnectionState.waiting && properties.isEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Client-side filtering
                properties = properties.where((p) {
                  final matchesSearch =
                      p.title.toLowerCase().contains(_searchQuery) ||
                      p.description.toLowerCase().contains(_searchQuery) ||
                      p.city.toLowerCase().contains(_searchQuery);
                  final matchesCity =
                      _selectedCity == null || p.city == _selectedCity;
                  final matchesType =
                      _selectedType == null || p.type == _selectedType;
                  final matchesPrice =
                      p.price >= _priceRange.start &&
                      p.price <= _priceRange.end;
                  return matchesSearch &&
                      matchesCity &&
                      matchesType &&
                      matchesPrice;
                }).toList();

                if (properties.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return PropertyCard(
                      property: property,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PropertyDetailsScreen(property: property),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAction(
    BuildContext context,
    firebase_auth.User? currentUser,
  ) {
    final authService = context.read<AuthService>();

    if (currentUser != null) {
      return FutureBuilder<UserModel?>(
        future: authService.getUserData(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          }
          final userModel = snapshot.data;
          if (userModel == null) return _buildLoginButton(context);
          return UserAvatarMenu(userModel: userModel);
        },
      );
    } else {
      return _buildLoginButton(context);
    }
  }

  Widget _buildLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: Text(
        'Login',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppConstants.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? AppConstants.primaryColor : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Properties Found',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any properties matching your current filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCity = null;
                  _selectedType = null;
                  _priceRange = const RangeValues(0, 500000);
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Property Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildModalChip(
                          label: 'Rental',
                          isSelected: _selectedType == PropertyType.rental,
                          onSelected: (val) => setModalState(
                            () => _selectedType = val ? PropertyType.rental : null,
                          ),
                        ),
                        _buildModalChip(
                          label: 'Bedsitter',
                          isSelected: _selectedType == PropertyType.bedsitter,
                          onSelected: (val) => setModalState(
                            () => _selectedType = val ? PropertyType.bedsitter : null,
                          ),
                        ),
                        _buildModalChip(
                          label: 'Airbnb',
                          isSelected: _selectedType == PropertyType.airbnb,
                          onSelected: (val) => setModalState(
                            () => _selectedType = val ? PropertyType.airbnb : null,
                          ),
                        ),
                        _buildModalChip(
                          label: 'On Sale',
                          isSelected: _selectedType == PropertyType.onSale,
                          onSelected: (val) => setModalState(
                            () => _selectedType = val ? PropertyType.onSale : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price Range',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'KSh ${_priceRange.start.round()} - ${_priceRange.end.round()}',
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 500000,
                      divisions: 50,
                      activeColor: AppConstants.primaryColor,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (values) => setState(
                        () => setModalState(() => _priceRange = values),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'createdAt',
                              child: Text('Newest First'),
                            ),
                            DropdownMenuItem(
                              value: 'price',
                              child: Text('Price: Low to High'),
                            ),
                          ],
                          onChanged: (val) => setState(
                            () => setModalState(() => _sortBy = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _propertiesStream = context
                                .read<PropertyService>()
                                .getProperties(sortBy: _sortBy);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppConstants.primaryColor.withValues(alpha: 0.1),
      checkmarkColor: AppConstants.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppConstants.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade50,
      side: BorderSide(
        color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
