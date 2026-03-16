import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../profile/profile_screen.dart';
import 'property_search_view.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'landing_page_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDialogShowing = false;
  firebase_auth.User? _previousUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserStatus();
    _checkUserRole();
  }

  void _checkUserStatus() {
    final currentUser = context.watch<firebase_auth.User?>();
    
    // If user just logged out
    if (_previousUser != null && currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedIndex = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed out')),
        );
      });
    }
    _previousUser = currentUser;
  }

  void _checkUserRole() {
    final userModel = context.watch<UserModel?>();
    if (userModel != null && userModel.role == UserRole.none && !_isDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRoleSelectionDialog();
      });
    }
  }

  void _showRoleSelectionDialog() {
    setState(() => _isDialogShowing = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Your Role',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To provide you with the best experience, please tell us how you plan to use GRAVON.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildRoleOption(
              context,
              role: UserRole.tenant,
              title: 'I am a Tenant',
              subtitle: 'I want to find and book properties',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 16),
            _buildRoleOption(
              context,
              role: UserRole.investor,
              title: 'I am a Landlord',
              subtitle: 'I want to list and manage properties',
              icon: Icons.business_outlined,
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isDialogShowing = false));
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () async {
        final authService = context.read<AuthService>();
        final userModel = context.read<UserModel?>();
        if (userModel != null) {
          try {
            await authService.updateUserRole(userModel.uid, role);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating role: $e')),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp() async {
    const phone = AppConstants.contactPhone;
    final whatsappUrl = Uri.parse("whatsapp://send?phone=${phone.replaceAll('+', '')}");
    final httpsUrl = Uri.parse("https://wa.me/${phone.replaceAll('+', '')}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to https which can be opened in browser
        await launchUrl(httpsUrl, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      // Final fallback to standard launch
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const LandingPageView(),
          const PropertySearchView(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        child: Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
