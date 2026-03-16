import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../property/property_details_screen.dart';
import '../../widgets/property_card.dart';
import '../../widgets/error_state_widget.dart';

class PropertyListView extends StatefulWidget {
  const PropertyListView({super.key});

  @override
  State<PropertyListView> createState() => _PropertyListViewState();
}

class _PropertyListViewState extends State<PropertyListView> {
  Stream<List<PropertyModel>>? _propertiesStream;

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    setState(() {
      _propertiesStream = context.read<PropertyService>().getProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PropertyModel>>(
      stream: _propertiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorStateWidget(
            error: snapshot.error!,
            onRetry: _refreshProperties,
          );
        }
        final properties = snapshot.data ?? [];
        if (properties.isEmpty) {
          return const Center(child: Text('No properties found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return PropertyCard(
              property: property,
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
    );
  }
}
