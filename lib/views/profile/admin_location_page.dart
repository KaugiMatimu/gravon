import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../models/location_model.dart';
import '../../utils/constants.dart';

class AdminLocationPage extends StatefulWidget {
  const AdminLocationPage({super.key});

  @override
  State<AdminLocationPage> createState() => _AdminLocationPageState();
}

class _AdminLocationPageState extends State<AdminLocationPage> {
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _addLocation() async {
    final name = _locationController.text.trim();
    if (name.isEmpty) return;

    final locationService = context.read<LocationService>();
    await locationService.addLocation(LocationModel(
      id: '', // Firestore will generate
      name: name,
      neighborhoods: [],
    ));
    _locationController.clear();
    if (mounted) Navigator.pop(context);
  }

  void _addArea(String locationId) async {
    final areaName = _areaController.text.trim();
    if (areaName.isEmpty) return;

    final locationService = context.read<LocationService>();
    await locationService.addNeighborhood(locationId, areaName);
    _areaController.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.read<LocationService>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Locations'),
        backgroundColor: AppConstants.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: () => _showAddLocationDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<LocationModel>>(
        stream: locationService.getActiveLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final locations = snapshot.data ?? [];

          if (locations.isEmpty) {
            return const Center(child: Text('No locations found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Text(
                    location.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${location.neighborhoods.length} areas'),
                  leading: const Icon(Icons.location_city_rounded, color: AppConstants.primaryColor),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => _showAddAreaDialog(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppConstants.errorColor),
                        onPressed: () => _confirmDeleteLocation(location),
                      ),
                    ],
                  ),
                  children: [
                    if (location.neighborhoods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No areas added yet.'),
                      ),
                    ...location.neighborhoods.map((area) => ListTile(
                          title: Text(area),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => locationService.removeNeighborhood(location.id, area),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Location'),
        content: TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location Name (e.g., Nairobi)',
            hintText: 'Enter city or town name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addLocation, child: const Text('Add')),
        ],
      ),
    );
  }

  void _showAddAreaDialog(LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Area to ${location.name}'),
        content: TextField(
          controller: _areaController,
          decoration: const InputDecoration(
            labelText: 'Area Name (e.g., Westlands)',
            hintText: 'Enter neighborhood or suburb',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => _addArea(location.id), child: const Text('Add')),
        ],
      ),
    );
  }

  void _confirmDeleteLocation(LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete ${location.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<LocationService>().deleteLocation(location.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );
  }
}
