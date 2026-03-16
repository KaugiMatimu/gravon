import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../widgets/error_state_widget.dart';
import '../property/add_property_screen.dart';
import '../property/landlord_cars_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../booking/booking_history_screen.dart';
import 'notifications_screen.dart';
import '../../services/notification_service.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
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
    final user = FirebaseAuth.instance.currentUser;
    final userModel = context.watch<UserModel?>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(userModel?.role == UserRole.agent ? 'Agent Console' : 'Landlord Console'),
        actions: [
          IconButton(
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandlordCarsScreen(),
                  ),
                );
              }
            },
            tooltip: 'Manage Cars',
            icon: const Icon(Icons.directions_car_outlined),
          ),
          IconButton(
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            onPressed: () async {
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
            icon: Icon(FontAwesomeIcons.whatsapp),
          ),
          StreamBuilder<int>(
            stream: context.read<NotificationService>().getUnreadCount(user?.uid ?? ''),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                child: IconButton(
                  onPressed: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(userId: user.uid),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>?>(
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

          return CustomScrollView(
            slivers: [
              // Statistics Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${userModel?.fullName.split(' ')[0] ?? (userModel?.role == UserRole.agent ? 'Agent' : 'Landlord')}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your listings and performance',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            'Total',
                            properties.length.toString(),
                            Icons.home_work_rounded,
                            AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            'Active',
                            properties.where((p) => p.isAvailable).length.toString(),
                            Icons.check_circle_rounded,
                            AppConstants.secondaryColor,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            'Hidden',
                            properties.where((p) => !p.isAvailable).length.toString(),
                            Icons.visibility_off_rounded,
                            Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Listings Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Listings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
              ),

              // Listings Grid/List
              if (properties.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_business_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('You haven\'t listed any properties yet'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                          ),
                          child: const Text('Add Your First Listing'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = properties[index];
                        return _buildPropertyListItem(context, context.read<PropertyService>(), p);
                      },
                      childCount: properties.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
        ),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyListItem(BuildContext context, PropertyService service, PropertyModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Image Placeholder
              Container(
                width: 100,
                color: Colors.grey.shade200,
                child: p.imageUrls.isNotEmpty
                    ? Image.network(p.imageUrls.first, fit: BoxFit.cover)
                    : const Icon(Icons.image, color: Colors.grey),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'KSh ${p.price}',
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.bed_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${p.bedrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                          Icon(Icons.bathtub_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${p.bathrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                width: 60,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        p.isAvailable ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: p.isAvailable ? AppConstants.secondaryColor : Colors.grey,
                      ),
                      onPressed: () => service.updateProperty(p.id, {'isAvailable': !p.isAvailable}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppConstants.primaryColor),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddPropertyScreen(property: p)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppConstants.errorColor),
                      onPressed: () => _confirmDelete(context, service, p.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PropertyService service, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('This action cannot be undone and will remove the property from all searches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              service.deleteProperty(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
