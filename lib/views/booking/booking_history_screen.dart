import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final userModel = context.watch<UserModel?>();

    if (user == null || userModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking History')),
        body: const Center(child: Text('Please login to view bookings')),
      );
    }

    final isInvestor = userModel.role == UserRole.investor;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          isInvestor ? 'Manage Bookings' : 'My Bookings',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: isInvestor
            ? context.read<BookingService>().getLandlordBookings(user.uid)
            : context.read<BookingService>().getTenantBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings found',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(context, booking, isInvestor);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking, bool isInvestor) {
    final authService = context.read<AuthService>();
    
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: booking.propertyImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: booking.propertyImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.home),
                    ),
            ),
            title: Text(
              booking.propertyTitle,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                FutureBuilder(
                  future: authService.getUserData(isInvestor ? booking.tenantId : booking.landlordId),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.fullName ?? '...';
                    return Text(
                      '${isInvestor ? 'Tenant' : 'Investor'}: $name',
                      style: GoogleFonts.montserrat(fontSize: 13),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${booking.startDate.toString().split(' ')[0]} to ${booking.endDate.toString().split(' ')[0]}',
                  style: GoogleFonts.montserrat(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(booking.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: booking.totalPrice > 0
                ? Text(
                    'KSh ${booking.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          if (isInvestor && booking.status == BookingStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, booking.id, BookingStatus.cancelled),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, booking.id, BookingStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  Future<void> _updateStatus(BuildContext context, String id, BookingStatus status) async {
    try {
      await context.read<BookingService>().updateBookingStatus(id, status);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
