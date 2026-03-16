import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
import '../../widgets/property_card.dart';
import '../../widgets/error_state_widget.dart';
import 'add_property_screen.dart';
import 'property_details_screen.dart';

class LandlordPropertiesScreen extends StatefulWidget {
  const LandlordPropertiesScreen({super.key});

  @override
  State<LandlordPropertiesScreen> createState() => _LandlordPropertiesScreenState();
}

class _LandlordPropertiesScreenState extends State<LandlordPropertiesScreen> {
  Stream<List<PropertyModel>?>? _propertiesStream;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    if (_userId != null) {
      setState(() {
        _propertiesStream = context.read<PropertyService>().getLandlordProperties(_userId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your properties')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Properties',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>?>(
        stream: _propertiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              error: snapshot.error!,
              onRetry: _refreshProperties,
            );
          }

          final properties = snapshot.data!;

          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t listed any properties yet',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
                      );
                    },
                    child: const Text('List Your First Property'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return PropertyCard(
                property: property,
                showManagementActions: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsScreen(property: property),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
