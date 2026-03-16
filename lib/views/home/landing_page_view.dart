import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../widgets/property_card.dart';
import '../../widgets/error_state_widget.dart';
import '../property/property_details_screen.dart';
import '../property/properties_screen.dart';
import '../property/add_property_screen.dart';
import '../property/add_car_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';
import 'car_hire_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/user_avatar_menu.dart';
// Removed unused firebase_core import

import 'package:url_launcher/url_launcher.dart';

class LandingPageView extends StatefulWidget {
  const LandingPageView({super.key});

  @override
  State<LandingPageView> createState() => _LandingPageViewState();
}

class _LandingPageViewState extends State<LandingPageView> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String selectedLocation = 'All Locations';
  String selectedType = 'Type';
  String selectedBedrooms = 'Bedrooms';
  String selectedSort = 'Newest';
  Stream<List<PropertyModel>?>? _propertiesStream;
  List<String> locations = ['All Locations'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
    // Initialize stream immediately
    _propertiesStream = context.read<PropertyService>().getFeaturedProperties();
    _loadLocations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLocations() {
    context.read<LocationService>().getActiveLocations().first.then((locs) {
      if (mounted) {
        setState(() {
          locations = ['All Locations', ...locs.map((l) => l.name)];
        });
      }
    });
  }

  final List<String> types = ['Type', 'Rental', 'Bedsitter', 'Airbnb', 'On Sale'];
  final List<String> bedrooms = ['Bedrooms', 'Any', '1+', '2+', '3+', '4+'];
  final List<String> sorts = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<firebase_auth.User?>();
    final userModel = context.watch<UserModel?>();

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              _buildHeroSection(context, currentUser, userModel),
              _buildStatsSection(),
              _buildOwnerCTASection(context, currentUser, userModel), // Moved above Explore Locations
              _buildLocationsSection(),
              _buildFeaturedSection(context),
              _buildWhyChooseUsSection(),
              _buildTestimonialsSection(),
              _buildFooterSection(context),
            ],
          ),
        ),
        _buildNavbar(context, currentUser, userModel),
      ],
    );
  }

  Widget _buildNavbar(
    BuildContext context,
    firebase_auth.User? currentUser,
    UserModel? userModel,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _isScrolled ? AppConstants.darkBlue : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
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
                ),
                const Spacer(),
                // Nav links (hide on small screens)
                if (constraints.maxWidth > 700)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Home',
                          style: GoogleFonts.montserrat(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PropertiesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Properties',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CarHireScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Car Hire',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (currentUser != null)
                        GestureDetector(
                          onTap: () async {
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
                              } catch (_) {}
                            }
                          },
                          child: Text(
                            'Contact Us',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(width: 24),
                    ],
                  ),
                // Right actions
                _buildUserAction(context, currentUser, userModel),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (currentUser == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      return;
                    }
                    if (userModel?.role != UserRole.investor) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please switch to Landlord mode to list property')),
                      );
                      return;
                    }
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
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildHeroSection(
    BuildContext context,
    firebase_auth.User? currentUser,
    UserModel? userModel,
  ) {
    return Stack(
      children: [
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.darkBlue,
              image: DecorationImage(
                image: const CachedNetworkImageProvider(
                  'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80',
                  maxHeight: 800,
                ),
                fit: BoxFit.cover,
                opacity: 0.25, // Slightly reduced to show more darkBlue
                colorFilter: ColorFilter.mode(
                  AppConstants.darkBlue.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(0, 80, 0, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Tagline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Kenya's Premier Property Platform",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Headline
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: 'Find Your Perfect '),
                      TextSpan(
                        text: 'Home',
                        style: TextStyle(color: AppConstants.primaryColor),
                      ),
                      const TextSpan(text: ' in Kenya'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover premium rental apartments and Airbnb properties across Nairobi, Mombasa, and beyond',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CarHireScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_car, color: Colors.white),
                  label: Text(
                    'Hire a Car',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // FILTER BAR
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildDropdown(
                          selectedLocation,
                          locations,
                          (val) => setState(() => selectedLocation = val!),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Color(0xFFE0E0E0),
                        ),
                        _buildDropdown(
                          selectedType,
                          types,
                          (val) => setState(() => selectedType = val!),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Color(0xFFE0E0E0),
                        ),
                        _buildDropdown(
                          selectedBedrooms,
                          bedrooms,
                          (val) => setState(() => selectedBedrooms = val!),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Color(0xFFE0E0E0),
                        ),
                        _buildDropdown(
                          selectedSort,
                          sorts,
                          (val) => setState(() => selectedSort = val!),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertiesScreen(
                                  initialLocation: selectedLocation,
                                  initialType: selectedType,
                                  initialBedrooms: selectedBedrooms,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Search',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildUserAction(
    BuildContext context,
    firebase_auth.User? currentUser,
    UserModel? userModel,
  ) {
    if (currentUser != null) {
      if (userModel == null) {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
      }
      return UserAvatarMenu(userModel: userModel);
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

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey[400],
            ),
          ),
          style: GoogleFonts.montserrat(color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildStatCard(
              Icons.business_outlined,
              '500+',
              'Properties Listed',
            ),
            const SizedBox(width: 16),
            _buildStatCard(Icons.location_on_outlined, '5', 'Major Cities'),
            const SizedBox(width: 16),
            _buildStatCard(Icons.home_outlined, '1000+', 'Happy Tenants'),
            const SizedBox(width: 16),
            _buildStatCard(
              Icons.verified_user_outlined,
              '100%',
              'Verified Listings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A2337),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Explore Locations',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse properties in Kenya\'s top cities',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AppConstants.locations.map((location) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PropertiesScreen(initialLocation: location['name']),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(location['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      location['name']!,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _refreshProperties() {
    setState(() {
      _propertiesStream = context.read<PropertyService>().getFeaturedProperties();
    });
  }

  Widget _buildFeaturedSection(BuildContext context) {
    // final propertyService = context.read<PropertyService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Properties',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hand-picked properties available now',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PropertiesScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.montserrat(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        StreamBuilder<List<PropertyModel>?>(
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Apply filters
            if (selectedLocation != 'All Locations') {
              properties = properties
                  .where((p) => p.city.contains(selectedLocation))
                  .toList();
            }
            if (selectedType != 'Type') {
              properties = properties
                  .where((p) =>
                      p.type.name.toLowerCase() ==
                      selectedType.replaceAll(' ', '').toLowerCase())
                  .toList();
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

            if (properties.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.home_work, size: 48, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        'No properties available yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to list a property!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine number of columns based on screen width
                  int crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : (constraints.maxWidth > 600 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length > 6 ? 6 : properties.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 440, // Fixed height for consistency
                    ),
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return PropertyCard(
                        property: property,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PropertyDetailsScreen(property: property),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSampleProperties(BuildContext context) {
    final sampleProperties = [
      {
        'title': 'Luxury Apartment in Kilimani',
        'city': 'Nairobi',
        'neighborhood': 'Kilimani',
        'price': 85000,
        'bedrooms': 2,
        'bathrooms': 2,
        'type': 'Rental',
        'image':
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80',
        'vacant': true,
      },
      {
        'title': 'Modern Studio in Westlands',
        'city': 'Nairobi',
        'neighborhood': 'Westlands',
        'price': 55000,
        'bedrooms': 1,
        'bathrooms': 1,
        'type': 'Rental',
        'image':
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80',
        'vacant': true,
      },
      {
        'title': 'Beachfront Villa in Nyali',
        'city': 'Mombasa',
        'neighborhood': 'Nyali',
        'price': 15000,
        'bedrooms': 4,
        'bathrooms': 3,
        'type': 'Airbnb',
        'image':
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
        'vacant': false,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 900
              ? 3
              : (constraints.maxWidth > 600 ? 2 : 1);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sampleProperties.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 10,
              mainAxisExtent: 380,
            ),
            itemBuilder: (context, index) {
              final prop = sampleProperties[index];
              return _buildSamplePropertyCard(prop, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildSamplePropertyCard(
    Map<String, dynamic> prop,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to view property details')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    prop['image']!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'vacant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prop['type']!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      'KES ${prop['price']!.toStringAsFixed(0)}${prop['type'] == 'Rental' ? '/month' : '/night'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prop['title']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2337),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${prop['neighborhood']}, ${prop['city']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Row(
                      children: [
                        _buildAmenity(
                          Icons.bed_outlined,
                          '${prop['bedrooms']} Beds',
                        ),
                        const SizedBox(width: 16),
                        _buildAmenity(
                          Icons.bathtub_outlined,
                          '${prop['bathrooms']} Baths',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCTASection(
    BuildContext context,
    firebase_auth.User? currentUser,
    UserModel? userModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(color: AppConstants.primaryColor),
      child: Column(
        children: [
          Text(
            'Earn with GRAVON',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'List your property or car and reach thousands of potential customers',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (currentUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                    return;
                  }
                  if (userModel?.role != UserRole.investor) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please switch to Landlord mode to list property')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPropertyScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.primaryColor,
                  minimumSize: const Size(160, 50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'List Property',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (currentUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                    return;
                  }
                  if (userModel?.role != UserRole.investor) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please switch to Landlord mode to list car')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCarScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.primaryColor,
                  minimumSize: const Size(160, 50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'List Car',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppConstants.darkBlue,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
            )
          ]),
          const SizedBox(height: 16),
          Text(
            'Kenya\'s premier property listing platform for rentals and Airbnb properties.',
            style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Links',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink(
                      'Browse Properties',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PropertiesScreen(),
                          ),
                        );
                      },
                    ),
                    _footerLink(
                      'List Property',
                      onTap: () {
                        final currentUser =
                            context.read<firebase_auth.User?>();
                        if (currentUser == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPropertyScreen(),
                          ),
                        );
                      },
                    ),
                    _footerLink(
                      'Car Hire',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CarHireScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locations',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink(
                      'Nairobi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PropertiesScreen(
                              initialLocation: 'Nairobi'),
                        ),
                      ),
                    ),
                    _footerLink(
                      'Mombasa',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PropertiesScreen(
                              initialLocation: 'Mombasa'),
                        ),
                      ),
                    ),
                    _footerLink(
                      'Nakuru',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PropertiesScreen(
                              initialLocation: 'Nakuru'),
                        ),
                      ),
                    ),
                    _footerLink(
                      'Eldoret',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PropertiesScreen(
                              initialLocation: 'Eldoret'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Contact',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _footerLink(AppConstants.contactEmail, onTap: () => _launchURL('mailto:${AppConstants.contactEmail}')),
          _footerLink(AppConstants.contactPhone, onTap: () => _launchURL('tel:${AppConstants.contactPhone}')),
          const SizedBox(height: 32),
          Text(
            'Follow Us',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _socialIcon(FontAwesomeIcons.facebookF, onTap: () => _launchURL(AppConstants.contactFacebook)),
              const SizedBox(width: 20),
              _socialIcon(FontAwesomeIcons.twitter),
              const SizedBox(width: 20),
              _socialIcon(FontAwesomeIcons.instagram),
              const SizedBox(width: 20),
              _socialIcon(FontAwesomeIcons.linkedinIn),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '© 2026 GRAVON. All rights reserved.',
              style: GoogleFonts.montserrat(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildWhyChooseUsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Why Choose GRAVON?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We provide the most seamless property hunting experience in Kenya',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  Icons.verified_user_rounded,
                  'Verified Listings',
                  'Every property on our platform is thoroughly verified for your safety.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChoiceCard(
                  Icons.flash_on_rounded,
                  'Instant Booking',
                  'Book your next Airbnb or rental viewing with just a few clicks.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  Icons.support_agent_rounded,
                  '24/7 Support',
                  'Our dedicated team is always here to help you with any inquiries.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChoiceCard(
                  Icons.account_balance_wallet_rounded,
                  'Transparent Pricing',
                  'No hidden fees. What you see is exactly what you pay.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    final List<Map<String, String>> testimonials = [
      {
        'name': 'Sarah Wangari',
        'role': 'Tenant in Kilimani',
        'content':
            'Finding an apartment in Nairobi was always a headache until I used Gravon. The verification process gave me peace of mind!',
        'image': 'assets/testimonials/woman2.webp',
      },
      {
        'name': 'James Omondi',
        'role': 'Airbnb Guest',
        'content':
            'Super easy to use. I booked a stay in Mombasa for my holiday and everything was exactly as shown in the pictures.',
        'image': 'assets/testimonials/omondi.webp',
      },
      {
        'name': 'Faith Mutua',
        'role': 'Property Owner',
        'content':
            'As an owner, listing my properties was seamless. I started getting inquiries within the first 24 hours!',
        'image': 'assets/testimonials/nwpg2ujktut5l5f572e6850c16.jpg',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'What Our Users Say',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join thousands of happy users finding their homes on GRAVON',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: testimonials.map((t) {
                return Container(
                  width: 320,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              t['image']!,
                            ),
                            radius: 25,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name']!,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  t['role']!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.format_quote,
                            color: AppConstants.primaryColor,
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t['content']!,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(
      size.width - (size.width / 3.25),
      size.height - 65,
    );
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
