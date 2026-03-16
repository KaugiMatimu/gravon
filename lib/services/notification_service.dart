import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a notification
  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required String relatedId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );

    await _db.collection('notifications').add(notification.toMap());
  }

  // Get notifications for a user
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final query = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
