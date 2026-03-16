import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/location_model.dart';

class LocationService {
  FirebaseFirestore get _db {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Please run "flutterfire configure".');
    }
    return FirebaseFirestore.instance;
  }

  // Fallback initial locations
  final List<LocationModel> _fallbackLocations = [
    LocationModel(id: '1', name: 'Nairobi', neighborhoods: [
      'Westlands',
      'Kilimani',
      'Karen',
      'Langata',
      'South C',
      'South B',
      'Parklands',
      'Lavington',
      'Hurlingham',
      'Runda',
      'Muthaiga',
      'Donholm',
      'Embakasi',
      'Kasarani',
      'Roysambu',
      'Kahawa Sukari',
      'Ngong Road',
      'Upper Hill',
      'Madaraka',
      'Pangani',
    ]),
    LocationModel(id: '2', name: 'Mombasa', neighborhoods: [
      'Nyali',
      'Bamburi',
      'Tudor',
      'Likoni',
      'Kizingo',
      'Shanzu',
      'Mtwapa',
      'Mikindani',
      'Changamwe',
      'Kongowea',
    ]),
    LocationModel(id: '3', name: 'Nakuru', neighborhoods: [
      'Milimani',
      'Lanet',
      'Naka',
      'Kiamunyi',
      'Section 58',
      'Free Area',
      'Ngata',
      'Shabaab',
    ]),
    LocationModel(id: '4', name: 'Eldoret City', neighborhoods: [
      'Elgon View',
      'Kapkapi',
      'Pioneer',
      'Annex',
      'Langas',
      'Huruma',
      'West Indies',
      'Maili Nne',
      'Racecourse',
      'Kimumu',
      'Kapsoya',
      'Rivatex',
    ]),
    LocationModel(id: '5', name: 'Kisumu', neighborhoods: [
      'Milimani',
      'Riat',
      'Kibos',
      'Nyamasaria',
      'Kondele',
      'Manyatta',
      'Tom Mboya',
      'Obunga',
      'Nyawita',
      'Mamboleo',
    ]),
    LocationModel(id: '6', name: 'Nyeri', neighborhoods: [
      'Nyeri Town',
      'Kiganjo',
      'Mathari',
      'King\'ong\'o',
      'Skuta',
      'Ruring\'u',
    ]),
    LocationModel(id: '7', name: 'Nyali', neighborhoods: [
      'Nyali Centre',
      'Links Road',
      'Old Nyali',
      'Cinemax',
    ]),
    LocationModel(id: '8', name: 'Thika', neighborhoods: [
      'Section 9',
      'Section 2',
      'Nanyuki Road',
      'Landless',
      'Thika Greens',
    ]),
    LocationModel(id: '9', name: 'Malindi', neighborhoods: [
      'Malindi Town',
      'Watamu',
      'Casuarina',
      'Sabaki',
    ]),
    LocationModel(id: '10', name: 'Kakamega', neighborhoods: [
      'Kakamega Town',
      'Lurambi',
      'Amalemba',
      'Milimani',
    ]),
  ];

  Stream<List<LocationModel>> getActiveLocations() {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(_fallbackLocations);
      
      return _db
          .collection('locations')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return _fallbackLocations;
        
        final List<LocationModel> firestoreLocations = snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data(), doc.id))
            .toList();
            
        // Merge with fallbacks to ensure comprehensive neighborhood lists
        return firestoreLocations.map((location) {
          final fallback = _fallbackLocations.firstWhere(
            (f) => f.name.toLowerCase() == location.name.toLowerCase(),
            orElse: () => location,
          );
          
          if (fallback != location) {
            // Create a unique set of neighborhoods from both sources
            final allNeighborhoods = <String>{
              ...location.neighborhoods,
              ...fallback.neighborhoods
            }.toList();
            
            // Sort them alphabetically for better UX
            allNeighborhoods.sort();
            
            return LocationModel(
              id: location.id,
              name: location.name,
              isActive: location.isActive,
              neighborhoods: allNeighborhoods,
            );
          }
          return location;
        }).toList();
      });
    } catch (e) {
      return Stream.value(_fallbackLocations);
    }
  }

  // Admin method to add location
  Future<void> addLocation(LocationModel location) async {
    await _db.collection('locations').add(location.toMap());
  }

  // Admin method to add neighborhood/area to a location
  Future<void> addNeighborhood(String locationId, String neighborhood) async {
    await _db.collection('locations').doc(locationId).update({
      'neighborhoods': FieldValue.arrayUnion([neighborhood])
    });
  }

  // Admin method to delete a location
  Future<void> deleteLocation(String locationId) async {
    await _db.collection('locations').doc(locationId).delete();
  }

  // Admin method to remove a neighborhood
  Future<void> removeNeighborhood(String locationId, String neighborhood) async {
    await _db.collection('locations').doc(locationId).update({
      'neighborhoods': FieldValue.arrayRemove([neighborhood])
    });
  }

  // Admin method to toggle location activity
  Future<void> toggleLocationStatus(String locationId, bool isActive) async {
    await _db.collection('locations').doc(locationId).update({
      'isActive': isActive
    });
  }
}
