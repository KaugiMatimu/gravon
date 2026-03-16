import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
import '../../widgets/property_card.dart';
import '../../widgets/error_state_widget.dart';
import 'property_details_screen.dart';

class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  Stream<List<PropertyModel>?>? _propertiesStream;

  void _refreshProperties(List<String> likedProperties) {
    setState(() {
      _propertiesStream = context.read<PropertyService>().getLikedProperties(likedProperties);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    
    if (userModel != null && _propertiesStream == null) {
      _propertiesStream = context.read<PropertyService>().getLikedProperties(userModel.likedProperties);
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Saved Properties',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
      ),
      body: userModel == null
          ? _buildLoginRequired(context)
          : StreamBuilder<List<PropertyModel>?>(
              stream: _propertiesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    error: snapshot.error!,
                    onRetry: () => _refreshProperties(userModel.likedProperties),
                  );
                }
                
                final properties = snapshot.data ?? [];
                
                if (properties.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    return PropertyCard(
                      property: properties[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailsScreen(property: properties[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Sign in to save properties',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep track of properties you like by signing in to your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No saved properties yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Properties you heart will appear here.',
            style: GoogleFonts.montserrat(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Properties'),
          ),
        ],
      ),
    );
  }
}
