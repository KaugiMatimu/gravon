import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../views/profile/profile_screen.dart';

class UserAvatarMenu extends StatelessWidget {
  final UserModel userModel;
  final Color textColor;

  const UserAvatarMenu({
    super.key,
    required this.userModel,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firstName = userModel.fullName.split(' ')[0];

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppConstants.primaryColor,
            backgroundImage: userModel.profileImageUrl != null
                ? NetworkImage(userModel.profileImageUrl!)
                : null,
            child: userModel.profileImageUrl == null
                ? Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            firstName,
            style: GoogleFonts.montserrat(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: textColor.withOpacity(0.7),
          ),
        ],
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 'settings':
            // Settings is currently part of ProfileScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 'logout':
            authService.signOut();
            Navigator.popUntil(context, (route) => route.isFirst);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 12),
              Text('Profile', style: GoogleFonts.montserrat(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 20),
              const SizedBox(width: 12),
              Text('Settings', style: GoogleFonts.montserrat(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: AppConstants.errorColor),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppConstants.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
