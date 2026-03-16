import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class BookingService {
  FirebaseFirestore get _db {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized.');
    }
    return FirebaseFirestore.instance;
  }

  // Create a booking
  Future<void> createBooking(BookingModel booking) async {
    final docRef = await _db.collection('bookings').add(booking.toMap());
    
    // Add notification for landlord
    await _db.collection('notifications').add({
      'userId': booking.landlordId,
      'title': 'New Booking Request',
      'body': 'You have a new booking for ${booking.propertyTitle}',
      'type': 'booking',
      'relatedId': docRef.id,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get bookings for a tenant
  Stream<List<BookingModel>> getTenantBookings(String tenantId) {
    return _db
        .collection('bookings')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get bookings for a landlord
  Stream<List<BookingModel>> getLandlordBookings(String landlordId) {
    return _db
        .collection('bookings')
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.toString().split('.').last,
    });

    // Notify tenant about status change
    final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
    if (bookingDoc.exists) {
      final bookingData = bookingDoc.data()!;
      await _db.collection('notifications').add({
        'userId': bookingData['tenantId'],
        'title': 'Booking Status Updated',
        'body': 'Your booking for ${bookingData['propertyTitle']} is now ${status.name}',
        'type': 'booking',
        'relatedId': bookingId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }
}
