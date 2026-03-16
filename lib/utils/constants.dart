import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'GRAVON';
  
  // Admin Configuration
  static const List<String> adminEmails = [
    'admin@gravon.com',
    'gravongroup@gmail.com',
  ];
  
  // Suggested password to set for the admin accounts in Firebase
  static const String adminDefaultPassword = 'Admin@Gravon2024';

  // Colors
  static const Color primaryColor = Color(0xFFFF9800); // Orange
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color darkBlue = Color(0xFF1A2337); // Footer/Hero background
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  
  // Padding/Margins
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double borderRadius = 12.0;
  
  // Text Styles (can be moved to theme but useful here too)
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // Contact Info
  static const String contactEmail = 'gravongroup@gmail.com';
  static const String contactFacebook = 'https://www.facebook.com/share/1Ac33Mf8fi/';
  static const String contactPhone = '+254719838935';

  // Mock Locations
  static const List<Map<String, String>> locations = [
    {'name': 'Nairobi', 'image': 'assets/city-images/nairobi.jpg'},
    {'name': 'Mombasa', 'image': 'assets/city-images/mombasa.jpg'},
    {'name': 'Kisumu', 'image': 'assets/city-images/kisumu.webp'},
    {'name': 'Nakuru', 'image': 'assets/city-images/nakuru.jpg'},
    {'name': 'Thika', 'image': 'assets/city-images/thika.jpg'},
    {'name': 'Malindi', 'image': 'assets/city-images/malindi.webp'},
    {'name': 'Kakamega', 'image': 'assets/city-images/kakamega.jpg'},
    {'name': 'Eldoret City', 'image': 'assets/city-images/nairobi.jpg'},
  ];
}
