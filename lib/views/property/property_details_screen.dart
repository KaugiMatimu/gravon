import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/property_service.dart';
import '../../widgets/property_card.dart';
import 'add_property_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainInfo(),
                      const SizedBox(height: 32),
                      _buildKeyFeatures(),
                      const SizedBox(height: 32),
                      _buildDescription(),
                      const SizedBox(height: 32),
                      _buildAmenities(),
                      const SizedBox(height: 32),
                      _buildLocationInfo(),
                      const SizedBox(height: 40),
                      _buildSimilarProperties(),
                      const SizedBox(height: 100), // Space for bottom action bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppConstants.darkBlue,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2337)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer<UserModel?>(
            builder: (context, userModel, _) {
              final isLiked = userModel?.likedProperties.contains(widget.property.id) ?? false;
              
              return CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : const Color(0xFF1A2337),
                  ),
                  onPressed: () {
                    if (userModel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please login to save properties')),
                      );
                      return;
                    }
                    context.read<PropertyService>().toggleLike(
                      userModel.uid,
                      widget.property.id,
                      isLiked,
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF1A2337)),
              onPressed: () {},
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.property.imageUrls.isNotEmpty ? widget.property.imageUrls.length : 1,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                if (widget.property.imageUrls.isEmpty) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.home_outlined, size: 100, color: Colors.grey),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: widget.property.imageUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Image Indicator
            if (widget.property.imageUrls.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.property.imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.property.type.name.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: AppConstants.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.property.title,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2337),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.grey, size: 18),
            const SizedBox(width: 4),
            Text(
              '${widget.property.neighborhood ?? ''}, ${widget.property.city}',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            children: [
              TextSpan(text: 'KSh ${widget.property.price.toStringAsFixed(0)}'),
              TextSpan(
                text: widget.property.type == PropertyType.airbnb ? ' / night' : ' / month',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyFeatures() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _featureItem(Icons.king_bed_outlined, '${widget.property.bedrooms} Beds'),
          _featureItem(Icons.bathtub_outlined, '${widget.property.bathrooms} Baths'),
          _featureItem(Icons.location_city_rounded, widget.property.city),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1A2337), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2337),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.property.description,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    if (widget.property.amenities.isEmpty) return const SizedBox.shrink();

    final Map<String, IconData> amenityIcons = {
      'WiFi': FontAwesomeIcons.wifi,
      'Parking': Icons.local_parking_rounded,
      'Swimming Pool': Icons.pool,
      'Gym': Icons.fitness_center,
      'Air Conditioning': Icons.ac_unit,
      'Security 24/7': Icons.security,
      'Borehole': Icons.water_drop,
      'Elevator': Icons.elevator,
      'Balcony': Icons.balcony,
      'Pet Friendly': Icons.pets,
      'Furnished': Icons.chair,
      'CCTV': Icons.videocam,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2337),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 40,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: widget.property.amenities.length,
          itemBuilder: (context, index) {
            final amenity = widget.property.amenities[index];
            return Row(
              children: [
                Icon(
                  amenityIcons[amenity] ?? Icons.check_circle_outline,
                  size: 18,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    amenity,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2337),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Located in ${widget.property.neighborhood ?? 'a prime area'} of ${widget.property.city}.',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProperties() {
    final propertyService = context.read<PropertyService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Properties',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2337),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 440,
          child: StreamBuilder<List<PropertyModel>?>(
            stream: propertyService.getProperties(),
            builder: (context, snapshot) {
              final properties = snapshot.data
                      ?.where((p) => p.id != widget.property.id && p.city == widget.property.city)
                      .take(4)
                      .toList() ??
                  [];
              
              if (properties.isEmpty) {
                return const Center(child: Text('No similar properties found'));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 20),
                    child: PropertyCard(
                      property: properties[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailsScreen(property: properties[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _initiateBooking() async {
    // Instead of performing the normal booking flow we now prompt the user
    // to contact via WhatsApp. This pop-up replaces the previous logic.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Find Your Perfect Stay'),
        content: const Text(
            'To book or view this property, chat with us directly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchWhatsApp();
            },
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBottomActionBar() {
    final user = context.watch<User?>();
    final isOwner = user != null &&
        widget.property.landlordId.trim().isNotEmpty &&
        user.uid.trim() == widget.property.landlordId.trim();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: isOwner
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddPropertyScreen(property: widget.property),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Manage Property',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A2337),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF1A2337)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: Icon(FontAwesomeIcons.whatsapp, size: 20, color: Color(0xFF1A2337)),
                        label: Text(
                          'WhatsApp',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A2337),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _initiateBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2337),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Booking/Viewing',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
