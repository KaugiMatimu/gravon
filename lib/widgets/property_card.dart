import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../utils/constants.dart';

import '../views/property/add_property_screen.dart';

import '../models/user_model.dart';

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool showManagementActions;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.showManagementActions = false,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool isHovered = false;

  void _deleteProperty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<PropertyService>().deleteProperty(widget.property.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppConstants.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && user.uid == widget.property.landlordId;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHovered
            ? (Matrix4.identity()
                ..scaleByVector3(vector_math.Vector3(1.02, 1.02, 1.0)))
            : Matrix4.identity(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.1 : 0.05),
                  blurRadius: isHovered ? 20 : 10,
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
                      child: widget.property.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.property.imageUrls[0],
                              height: 200,
                              width: double.infinity,
                              memCacheHeight: 400, // Optimize memory usage
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.home,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    // Badges
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          _buildBadge(
                            'vacant',
                            const Color(0xFF00C853),
                            Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            widget.property.type == PropertyType.rental
                                ? 'Rental'
                                : 'Airbnb',
                            Colors.white.withOpacity(0.9),
                            Colors.black87,
                          ),
                          if (widget.showManagementActions && !widget.property.isApproved) ...[
                            const SizedBox(width: 8),
                            _buildBadge(
                              'Pending Approval',
                              Colors.orange,
                              Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Management Actions Overlay
                    if (widget.showManagementActions && isOwner)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddPropertyScreen(property: widget.property),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteProperty,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppConstants.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Favorite Icon
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Consumer<UserModel?>(
                          builder: (context, userModel, _) {
                            final isLiked = userModel?.likedProperties.contains(widget.property.id) ?? false;
                            
                            return GestureDetector(
                              onTap: () {
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
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: isLiked ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Price Overlay
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
                          'KES ${widget.property.price.toStringAsFixed(0)}${widget.property.type == PropertyType.rental ? '/month' : '/night'}',
                          style: GoogleFonts.montserrat(
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
                        widget.property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A2337),
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
                              '${widget.property.neighborhood != null ? '${widget.property.neighborhood}, ' : ''}${widget.property.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
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
                          border: Border(
                            top: BorderSide(color: Colors.grey[100]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildAmenity(
                              Icons.bed_outlined,
                              '${widget.property.bedrooms} Beds',
                            ),
                            const SizedBox(width: 16),
                            _buildAmenity(
                              Icons.bathtub_outlined,
                              '${widget.property.bathrooms} Baths',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.darkBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Booking/Viewing',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
          style: GoogleFonts.montserrat(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
