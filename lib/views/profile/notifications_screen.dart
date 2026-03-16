import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../booking/booking_history_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notificationService.markAllAsRead(userId),
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.transparent : AppConstants.primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor(notification.type).withOpacity(0.1),
          child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        onTap: () => _handleTap(context, notificationService),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return FontAwesomeIcons.whatsapp;
      case NotificationType.booking:
        return Icons.calendar_today_outlined;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return AppConstants.primaryColor;
      case NotificationType.booking:
        return AppConstants.secondaryColor;
    }
  }

  void _handleTap(BuildContext context, NotificationService service) async {
    service.markAsRead(notification.id);

    if (notification.type == NotificationType.chat) {
      // direct user to WhatsApp instead of in-app chat
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
    } else if (notification.type == NotificationType.booking) {
      // Navigate to bookings
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingHistoryScreen(),
        ),
      );
    }
  }
}
