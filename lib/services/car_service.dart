import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/car_model.dart';

class CarService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Upload image - Updated to support Web and Mobile using XFile
  Future<String> uploadImage(XFile image, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final bytes = await image.readAsBytes();
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      // putData works on all platforms
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('CarService Upload Error: $e');
      rethrow;
    }
  }

  // Add car
  Future<void> addCar(CarModel car) async {
    await _db.collection('cars').add(car.toMap());
  }

  // Update car
  Future<void> updateCar(String id, Map<String, dynamic> data) async {
    await _db.collection('cars').doc(id).update(data);
  }

  // Delete car
  Future<void> deleteCar(String id) async {
    await _db.collection('cars').doc(id).delete();
  }

  Stream<List<CarModel>?> getCars({
    String? sortBy,
    bool descending = true,
    int? limit,
    bool approvedOnly = false,
  }) {
    // We use where() in the Firestore query but keep sorting in memory
    // to avoid requiring composite indices while respecting security rules
    Query query = _db.collection('cars');

    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var cars = snapshot.docs.map((doc) {
        try {
          return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print('Error parsing car ${doc.id}: $e');
          return null;
        }
      }).whereType<CarModel>().toList();

      // Sort in memory
      String sortField = sortBy ?? 'createdAt';
      cars.sort((a, b) {
        dynamic valA;
        dynamic valB;

        if (sortField == 'price') {
          valA = a.pricePerDay;
          valB = b.pricePerDay;
        } else {
          valA = a.createdAt;
          valB = b.createdAt;
        }

        if (valA == null || valB == null) return 0;
        return descending ? valB.compareTo(valA) : valA.compareTo(valB);
      });

      if (limit != null && cars.length > limit) {
        cars = cars.sublist(0, limit);
      }

      return cars;
    });
  }

  Stream<List<CarModel>?> getFeaturedCars() {
    return getCars(limit: 6, approvedOnly: true);
  }

  // Get cars by owner
  Stream<List<CarModel>?> getOwnerCars(String ownerId) {
    return _db
        .collection('cars')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      var cars = snapshot.docs
          .map((doc) {
            try {
              return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<CarModel>()
          .toList();

      // Sort by createdAt descending in memory
      cars.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cars;
    });
  }

  // Get cars by city
  Stream<List<CarModel>?> getCarsByCity(String city) {
    return _db
        .collection('cars')
        .where('city', isEqualTo: city)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var cars = snapshot.docs
          .map((doc) {
            try {
              return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<CarModel>()
          .toList();

      // Sort by createdAt descending in memory
      cars.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cars;
    });
  }

  // Search cars
  Stream<List<CarModel>?> searchCars(String query) {
    // For search, we still fetch all and filter in memory since Firestore search is limited
    // But we fetch directly from snapshots to ensure it's real-time
    return _db.collection('cars').snapshots().map((snapshot) {
      final cars = snapshot.docs.map((doc) {
        try {
          return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          return null;
        }
      }).whereType<CarModel>().toList();

      final lowerQuery = query.toLowerCase();
      return cars.where((c) {
        return (c.make.toLowerCase().contains(lowerQuery) ||
                c.model.toLowerCase().contains(lowerQuery) ||
                c.displayName.toLowerCase().contains(lowerQuery) ||
                c.description.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }
}
