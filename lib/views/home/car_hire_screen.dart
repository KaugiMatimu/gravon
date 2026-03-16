import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/car_model.dart';
import '../../services/car_service.dart';
import '../../utils/constants.dart';

class CarHireScreen extends StatefulWidget {
  const CarHireScreen({super.key});

  @override
  State<CarHireScreen> createState() => _CarHireScreenState();
}

class _CarHireScreenState extends State<CarHireScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final carService = context.read<CarService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Car Hire',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.darkBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cars...',
                prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CarModel>?>(
              stream: _searchQuery.isEmpty
                  ? carService.getCars()
                  : carService.searchCars(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // provide a friendlier message for permission errors
                  final errorText = snapshot.error.toString();
                  String displayMessage = 'Unable to load cars.';
                  if (errorText.contains('permission-denied')) {
                    displayMessage += '\nPlease ensure your Firestore security rules allow public reads '
                        'or that you are signed in with the appropriate account.';
                  } else {
                    displayMessage += ' $errorText';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          displayMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final cars = snapshot.data ?? [];

                if (cars.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No cars available at the moment'
                              : 'No cars match your search',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    return _buildCarCard(context, car);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, CarModel car) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (car.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                car.imageUrls[0],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Icon(Icons.directions_car, size: 64, color: Colors.grey),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.displayName,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            car.color,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSh ${car.pricePerDay.toStringAsFixed(0)}/day',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  car.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildInfoChip(Icons.event_seat, '${car.seats} seats'),
                    _buildInfoChip(Icons.local_gas_station, car.fuelType.toString().split('.').last),
                    _buildInfoChip(Icons.location_on, car.city),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // show smart popup directing users to WhatsApp
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Book Your Car in Minutes'),
                          content: const Text(
                              'To hire this car, chat with us directly.'),
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Hire Now',
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
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
