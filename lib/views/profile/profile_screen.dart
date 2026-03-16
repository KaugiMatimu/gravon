import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import 'landlord_dashboard.dart';
import 'admin_dashboard.dart';
import '../auth/login_screen.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../property/saved_properties_screen.dart';
import '../booking/booking_history_screen.dart';
import 'personal_info_screen.dart';
import 'notification_settings_screen.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';
import '../../services/notification_service.dart';
import '../home/about_us_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final userModel = context.watch<UserModel?>();
    final authService = context.read<AuthService>();

    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_outline_rounded, size: 80, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 32),
                Text(
                  'Join GRAVON Today',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to manage your favorite properties, bookings, and listings effortlessly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Login / Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userModel == null) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: AppConstants.darkBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userModel != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalInfoScreen(user: userModel),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppConstants.primaryColor,
                            backgroundImage: userModel.profileImageUrl != null
                                ? NetworkImage(userModel.profileImageUrl!)
                                : null,
                            child: userModel.profileImageUrl == null
                                ? Text(
                                    userModel.fullName.isNotEmpty
                                        ? userModel.fullName.split(' ')[0][0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppConstants.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userModel.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userModel.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userModel.role.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (userModel?.role == UserRole.investor || userModel?.role == UserRole.agent) ...[
                  _buildMenuSection('Management'),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_customize_rounded,
                    title: userModel?.role == UserRole.investor ? 'Investor Console' : 'Agent Console',
                    subtitle: 'Manage listings, view insights',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LandlordDashboard()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (userModel?.isAdmin == true) ...[
                  _buildMenuSection('Administration'),
                  _buildMenuItem(
                    context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Console',
                    subtitle: 'System-wide management',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildMenuSection('Account'),
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  onTap: () {
                    if (userModel != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonalInfoScreen(user: userModel),
                        ),
                      );
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  title: 'Switch Role',
                  subtitle: 'Current: ${userModel?.role.toString().split('.').last}',
                  onTap: () => _showSwitchRoleDialog(context, userModel, authService),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved Properties',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Booking History',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'Contact Us',
                  onTap: () async {
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
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  subtitle: 'Learn more about GRAVON',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuSection('Settings'),
                StreamBuilder<int>(
                  stream: context.read<NotificationService>().getUnreadCount(userModel.uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildMenuItem(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailing: count > 0 
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationsScreen(userId: userModel.uid)),
                      ),
                    );
                  }
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Security',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => _showHelpSupportDialog(context),
                ),
                const SizedBox(height: 24),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  textColor: AppConstants.errorColor,
                  onTap: () {
                    authService.signOut();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  showChevron: false,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildContactTile(
              context,
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: AppConstants.contactEmail,
              onTap: () => _launchURL('mailto:${AppConstants.contactEmail}'),
            ),
            _buildContactTile(
              context,
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: AppConstants.contactPhone,
              onTap: () => _launchURL('tel:${AppConstants.contactPhone}'),
            ),
            _buildContactTile(
              context,
              icon: FontAwesomeIcons.facebook,
              title: 'Facebook',
              subtitle: 'Visit our page',
              onTap: () => _launchURL(AppConstants.contactFacebook),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showSwitchRoleDialog(BuildContext context, UserModel? userModel, AuthService authService) {
    if (userModel == null) return;
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Switch Role'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Select your active account role:', style: TextStyle(color: Colors.grey.shade600)),
          ),
          _buildRoleOption(context, 'Tenant', Icons.person_outline, userModel.role == UserRole.tenant, () async {
            await authService.updateUserRole(userModel.uid, UserRole.tenant);
            if (context.mounted) Navigator.pop(context);
          }),
          _buildRoleOption(context, 'Investor', Icons.home_work_outlined, userModel.role == UserRole.investor, () async {
            await authService.updateUserRole(userModel.uid, UserRole.investor);
            if (context.mounted) Navigator.pop(context);
          }),
          if (userModel.isAdmin)
            _buildRoleOption(context, 'Admin', Icons.admin_panel_settings_outlined, userModel.role == UserRole.admin, () async {
              await authService.updateUserRole(userModel.uid, UserRole.admin);
              if (context.mounted) Navigator.pop(context);
            }),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(BuildContext context, String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppConstants.primaryColor : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppConstants.primaryColor) : null,
      onTap: isSelected ? null : onTap,
    );
  }

  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    bool showChevron = true,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (textColor ?? AppConstants.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textColor ?? AppConstants.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              )
            : null,
        trailing: trailing ?? (showChevron ? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400) : null),
        onTap: onTap,
      ),
    );
  }
}
