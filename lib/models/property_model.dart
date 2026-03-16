import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType { rental, airbnb, onSale, bedsitter }

class PropertyModel {
  final String id;
  final String landlordId;
  final String title;
  final String description;
  final double price;
  final String city;
  final String? neighborhood;
  final PropertyType type;
  final List<String> imageUrls;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final bool isAvailable; // Admin/Landlord toggle
  final bool isBooked; // For Airbnb states
  final bool isApproved; // Admin approval status
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.title,
    required this.description,
    required this.price,
    required this.city,
    this.neighborhood,
    required this.type,
    required this.imageUrls,
    this.amenities = const [],
    required this.bedrooms,
    required this.bathrooms,
    this.isAvailable = true,
    this.isBooked = false,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'title': title,
      'description': description,
      'price': price,
      'city': city,
      'neighborhood': neighborhood,
      'type': type.toString().split('.').last,
      'imageUrls': imageUrls,
      'amenities': amenities,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'isAvailable': isAvailable,
      'isBooked': isBooked,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    bool parseBool(dynamic value, bool defaultValue) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value == 1;
      return defaultValue;
    }

    return PropertyModel(
      id: id,
      landlordId: map['landlordId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'No Title',
      description: map['description']?.toString() ?? 'No Description',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      city: map['city']?.toString() ?? 'Unknown City',
      neighborhood: map['neighborhood']?.toString(),
      type: PropertyType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PropertyType.rental,
      ),
      imageUrls: map['imageUrls'] is List ? List<String>.from(map['imageUrls']) : [],
      amenities: map['amenities'] is List ? List<String>.from(map['amenities']) : [],
      bedrooms: int.tryParse(map['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(map['bathrooms']?.toString() ?? '0') ?? 0,
      isAvailable: parseBool(map['isAvailable'], true),
      isBooked: parseBool(map['isBooked'], false),
      isApproved: parseBool(map['isApproved'], false),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
