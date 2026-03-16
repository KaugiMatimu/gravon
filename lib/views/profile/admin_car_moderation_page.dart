import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/car_service.dart';
import '../../models/car_model.dart';
import '../../utils/constants.dart';
import '../../widgets/error_state_widget.dart';

class AdminCarModerationPage extends StatefulWidget {
  const AdminCarModerationPage({super.key});

  @override
  State<AdminCarModerationPage> createState() => _AdminCarModerationPageState();
}

class _AdminCarModerationPageState extends State<AdminCarModerationPage> {
  Stream<List<CarModel>?>? _carsStream;

  @override
  void initState() {
    super.initState();
    _refreshCars();
  }

  void _refreshCars() {
    setState(() {
      _carsStream = context.read<CarService>().getCars(
            approvedOnly: false,
          );
    });
  }

  Future<void> _approveCar(CarModel car) async {
    try {
      await context.read<CarService>().updateCar(car.id, {
        'isApproved': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car approved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving car: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCar(CarModel car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car Listing'),
        content: const Text('Are you sure you want to delete this car listing? This action cannot be undone.'),
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
        await context.read<CarService>().deleteCar(car.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting car: $e'), backgroundColor: Colors.red),
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
        title: const Text('Car Moderation'),
        backgroundColor: AppConstants.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CarModel>?>(
        stream: _carsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateWidget(
              error: snapshot.error!,
              onRetry: _refreshCars,
            );
          }
          if (_carsStream == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCars = snapshot.data ?? [];
          final pendingCars = allCars.where((c) => !c.isApproved).toList();

          if (pendingCars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No cars pending approval.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingCars.length,
            itemBuilder: (context, index) {
              final car = pendingCars[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: car.imageUrls.isNotEmpty 
                        ? Image.network(car.imageUrls.first, width: 80, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.directions_car),
                      title: Text('${car.year} ${car.make} ${car.model}'),
                      subtitle: Text('KES ${car.pricePerDay} / day'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _deleteCar(car),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _approveCar(car),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
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
