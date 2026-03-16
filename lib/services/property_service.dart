import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_model.dart';

class PropertyService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Upload image - Updated to support Web and Mobile using XFile
  Future<String> uploadImage(XFile image, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final bytes = await image.readAsBytes();
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      // putData works on all platforms (Web, Android, iOS)
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('PropertyService Upload Error: $e');
      rethrow;
    }
  }

  Future<void> addProperty(PropertyModel property) async {
    await _db.collection('properties').add(property.toMap());
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _db.collection('properties').doc(id).update(data);
  }

  Future<void> deleteProperty(String id) async {
    await _db.collection('properties').doc(id).delete();
  }

  Stream<List<PropertyModel>?> getProperties({
    String? sortBy,
    bool descending = true,
    int? limit,
    bool approvedOnly = false,
  }) {
    // We use where() in the Firestore query but keep sorting in memory
    // to avoid requiring composite indices while respecting security rules
    Query query = _db.collection('properties');

    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var properties = snapshot.docs.map((doc) {
        try {
          return PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print('Error parsing property ${doc.id}: $e');
          return null;
        }
      }).whereType<PropertyModel>().toList();

      // Sort in memory
      String sortField = sortBy ?? 'createdAt';
      properties.sort((a, b) {
        dynamic valA;
        dynamic valB;

        if (sortField == 'price') {
          valA = a.price;
          valB = b.price;
        } else {
          // Default to createdAt
          valA = a.createdAt;
          valB = b.createdAt;
        }

        if (valA == null || valB == null) return 0;
        return descending ? valB.compareTo(valA) : valA.compareTo(valB);
      });

      if (limit != null && properties.length > limit) {
        properties = properties.sublist(0, limit);
      }

      return properties;
    });
  }

  Stream<List<PropertyModel>?> getFeaturedProperties() {
    return getProperties(limit: 6, approvedOnly: true);
  }

  Stream<List<PropertyModel>?> getLandlordProperties(String landlordId) {
    return _db
        .collection('properties')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) {
      var properties = snapshot.docs
          .map((doc) {
            try {
              return PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<PropertyModel>()
          .toList();

      // Sort by createdAt descending in memory
      properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return properties;
    });
  }

  Future<void> toggleLike(String userId, String propertyId, bool isLiked) async {
    final userRef = _db.collection('users').doc(userId);
    if (isLiked) {
      await userRef.update({
        'likedProperties': FieldValue.arrayRemove([propertyId])
      });
    } else {
      await userRef.update({
        'likedProperties': FieldValue.arrayUnion([propertyId])
      });
    }
  }

  Stream<List<PropertyModel>?> getLikedProperties(List<String> propertyIds) {
    if (propertyIds.isEmpty) return Stream.value([]);
    
    // Fetch directly from snapshots to ensure real-time updates for liked properties too
    return _db.collection('properties').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<PropertyModel>()
          .where((p) => propertyIds.contains(p.id))
          .toList();
    });
  }
}
