import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'add_property_screen.dart';
import '../../widgets/property_card.dart';
import '../../widgets/user_avatar_menu.dart';
import '../../widgets/error_state_widget.dart';
import 'property_details_screen.dart';

class PropertiesScreen extends StatefulWidget {
  final String? initialLocation;
  final String? initialType;
  final String? initialBedrooms;

  const PropertiesScreen({
    super.key,
    this.initialLocation,
    this.initialType,
    this.initialBedrooms,
  });

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  late String selectedLocation;
  late String selectedType;
  String selectedBedrooms = 'Bedrooms';
  String selectedSort = 'Newest';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Stream<List<PropertyModel>?>? _propertiesStream;

  void _launchWhatsApp() async {
    const phone = AppConstants.contactPhone;
    final whatsappUrl = Uri.parse("whatsapp://send?phone=${phone.replaceAll('+', '')}");
    final httpsUrl = Uri.parse("https://wa.me/${phone.replaceAll('+', '')}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(httpsUrl, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      try {
        await launchUrl(httpsUrl, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    }
  }

  final List<String> locations = [
    'All Locations',
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret City',
    'Thika',
    'Malindi',
    'Kakamega',
  ];
  final List<String> types = ['Type', 'Rental', 'Bedsitter', 'Airbnb', 'On Sale'];
  final List<String> bedroomsList = ['Bedrooms', 'Any', '1+', '2+', '3+', '4+'];
  final List<String> sorts = ['Newest', 'Price: Low to High', 'Price: High to Low'];

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation ?? 'All Locations';
    selectedType = widget.initialType ?? 'Type';
    selectedBedrooms = widget.initialBedrooms ?? 'Bedrooms';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _propertiesStream = _createPropertiesStream();
        });
      }
    });
  }

  Stream<List<PropertyModel>?> _createPropertiesStream() {
    return context.read<PropertyService>().getProperties().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<firebase_auth.User?>();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        child: Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      body: Column(
        children: [
          // NAVBAR - matching landing page
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
                        Image.asset('transparent-logo.png', height: 26),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  _buildFilterSection(),
                  _buildResultsSection(),
                ],
              ),
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

  Widget _buildHeaderSection() {
    return StreamBuilder<List<PropertyModel>?>(
      stream: _propertiesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError || _propertiesStream == null || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        int count = snapshot.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Properties',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2337),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count properties available',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by property name or description...',
              hintStyle: GoogleFonts.montserrat(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[100]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[100]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppConstants.primaryColor),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                    width: 150,
                    child: _buildDropdown(selectedLocation, locations,
                        (v) => setState(() => selectedLocation = v!))),
                _divider(),
                SizedBox(
                    width: 120,
                    child: _buildDropdown(selectedType, types,
                        (v) => setState(() => selectedType = v!))),
                _divider(),
                SizedBox(
                    width: 130,
                    child: _buildDropdown(selectedBedrooms, bedroomsList,
                        (v) => setState(() => selectedBedrooms = v!))),
                _divider(),
                SizedBox(
                    width: 180,
                    child: _buildDropdown(selectedSort, sorts,
                        (v) => setState(() => selectedSort = v!))),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLocation = 'All Locations';
                      selectedType = 'Type';
                      selectedBedrooms = 'Bedrooms';
                      selectedSort = 'Newest';
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey[200]);

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[400]),
        ),
      ),
    );
  }

  void _refreshProperties() {
    setState(() {
      _propertiesStream = _createPropertiesStream();
    });
  }

  Widget _buildResultsSection() {
    return StreamBuilder<List<PropertyModel>?>(
      stream: _propertiesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget(
            error: snapshot.error!,
            onRetry: _refreshProperties,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ));
        }

        var properties = snapshot.data!;

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          properties = properties.where((p) => 
            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            p.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        if (selectedLocation != 'All Locations') {
          properties = properties.where((p) => p.city.contains(selectedLocation)).toList();
        }
        if (selectedType != 'Type') {
          properties = properties.where((p) => p.type.name.toLowerCase() == selectedType.replaceAll(' ', '').toLowerCase()).toList();
        }
        if (selectedBedrooms != 'Bedrooms' && selectedBedrooms != 'Any') {
          try {
            int count = int.parse(selectedBedrooms.replaceAll('+', ''));
            properties = properties.where((p) => p.bedrooms >= count).toList();
          } catch (e) {
            // Ignore parsing errors
          }
        }

        // Apply sorting
        if (selectedSort == 'Price: Low to High') {
          properties.sort((a, b) => a.price.compareTo(b.price));
        } else if (selectedSort == 'Price: High to Low') {
          properties.sort((a, b) => b.price.compareTo(a.price));
        } else {
          properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${properties.length} results',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      _viewIcon(Icons.grid_view_rounded, true),
                      const SizedBox(width: 8),
                      _viewIcon(Icons.format_list_bulleted_rounded, false),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  int cols = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 0,
                      mainAxisExtent: 440,
                    ),
                    itemBuilder: (context, index) {
                      return PropertyCard(
                        property: properties[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailsScreen(property: properties[index]),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _viewIcon(IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? Colors.orange : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: active ? null : Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(icon, size: 18, color: active ? Colors.white : Colors.grey[400]),
    );
  }
}
