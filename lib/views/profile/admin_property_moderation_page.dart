import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../utils/constants.dart';
import '../../widgets/property_card.dart';
import '../../widgets/error_state_widget.dart';
import '../property/property_details_screen.dart';

class AdminPropertyModerationPage extends StatefulWidget {
  const AdminPropertyModerationPage({super.key});

  @override
  State<AdminPropertyModerationPage> createState() => _AdminPropertyModerationPageState();
}

class _AdminPropertyModerationPageState extends State<AdminPropertyModerationPage> {
  Stream<List<PropertyModel>?>? _propertiesStream;
  bool _showOnlyPending = true;

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    setState(() {
      _propertiesStream = context.read<PropertyService>().getProperties(
            approvedOnly: false,
          );
    });
  }

  Future<void> _approveProperty(PropertyModel property) async {
    try {
      await context.read<PropertyService>().updateProperty(property.id, {
        'isApproved': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property approved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving property: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProperty(PropertyModel property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<PropertyService>().deleteProperty(property.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting property: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Property Moderation'),
        backgroundColor: AppConstants.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showOnlyPending ? Icons.filter_list_rounded : Icons.filter_list_off_rounded),
            onPressed: () => setState(() => _showOnlyPending = !_showOnlyPending),
            tooltip: _showOnlyPending ? 'Show All' : 'Show Pending Only',
          ),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>?>(
        stream: _propertiesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateWidget(
              error: snapshot.error!,
              onRetry: _refreshProperties,
            );
          }
          if (_propertiesStream == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProperties = snapshot.data ?? [];
          final displayedProperties = _showOnlyPending 
              ? allProperties.where((p) => !p.isApproved).toList()
              : allProperties;

          if (displayedProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showOnlyPending ? Icons.check_circle_outline : Icons.home_work_outlined, 
                    size: 64, 
                    color: Colors.grey
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyPending ? 'All Caught Up!' : 'No Properties Found',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showOnlyPending 
                        ? 'No properties pending approval.'
                        : 'There are no properties in the system.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayedProperties.length,
            itemBuilder: (context, index) {
              final property = displayedProperties[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    PropertyCard(
                      property: property,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailsScreen(property: property),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (property.isApproved)
                            const Chip(
                              label: Text('Approved'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _approveProperty(property),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _deleteProperty(property),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
