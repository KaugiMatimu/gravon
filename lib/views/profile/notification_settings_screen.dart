import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _bookingUpdates = true;
  bool _newMessages = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('General'),
          _buildToggleTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          _buildToggleTile(
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Activity'),
          _buildToggleTile(
            title: 'Booking Updates',
            subtitle: 'Status changes on your bookings',
            value: _bookingUpdates,
            onChanged: (val) => setState(() => _bookingUpdates = val),
          ),
          _buildToggleTile(
            title: 'New Messages',
            subtitle: 'Notifications for new chat messages',
            value: _newMessages,
            onChanged: (val) => setState(() => _newMessages = val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Marketing'),
          _buildToggleTile(
            title: 'Promotions & Offers',
            subtitle: 'Receive updates on new deals',
            value: _promotions,
            onChanged: (val) => setState(() => _promotions = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.darkBlue,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: AppConstants.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
