import 'package:cloud_firestore/cloud_firestore.dart';

enum CarType { sedan, suv, van, hatchback, convertible }
enum FuelType { petrol, diesel, electric, hybrid }

class CarModel {
  final String id;
  final String ownerId;
  final String make;
  final String model;
  final String year;
  final String color;
  final double pricePerDay;
  final String description;
  final int seats;
  final int fuelCapacity;
  final FuelType fuelType;
  final CarType carType;
  final int mileage;
  final List<String> imageUrls;
  final List<String> features;
  final String city;
  final String? neighborhood;
  final bool isAvailable;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarModel({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.pricePerDay,
    required this.description,
    required this.seats,
    required this.fuelCapacity,
    required this.fuelType,
    required this.carType,
    required this.mileage,
    required this.imageUrls,
    this.features = const [],
    required this.city,
    this.neighborhood,
    this.isAvailable = true,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'pricePerDay': pricePerDay,
      'description': description,
      'seats': seats,
      'fuelCapacity': fuelCapacity,
      'fuelType': fuelType.toString().split('.').last,
      'carType': carType.toString().split('.').last,
      'mileage': mileage,
      'imageUrls': imageUrls,
      'features': features,
      'city': city,
      'neighborhood': neighborhood,
      'isAvailable': isAvailable,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
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

    return CarModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      make: map['make']?.toString() ?? 'Unknown',
      model: map['model']?.toString() ?? 'Unknown',
      year: map['year']?.toString() ?? 'Unknown',
      color: map['color']?.toString() ?? 'Unknown',
      pricePerDay: double.tryParse(map['pricePerDay']?.toString() ?? '0') ?? 0.0,
      description: map['description']?.toString() ?? 'No Description',
      seats: int.tryParse(map['seats']?.toString() ?? '5') ?? 5,
      fuelCapacity: int.tryParse(map['fuelCapacity']?.toString() ?? '60') ?? 60,
      fuelType: FuelType.values.firstWhere(
        (e) => e.toString().split('.').last == map['fuelType'],
        orElse: () => FuelType.petrol,
      ),
      carType: CarType.values.firstWhere(
        (e) => e.toString().split('.').last == map['carType'],
        orElse: () => CarType.sedan,
      ),
      mileage: int.tryParse(map['mileage']?.toString() ?? '0') ?? 0,
      imageUrls: map['imageUrls'] is List ? List<String>.from(map['imageUrls']) : [],
      features: map['features'] is List ? List<String>.from(map['features']) : [],
      city: map['city']?.toString() ?? 'Unknown City',
      neighborhood: map['neighborhood']?.toString(),
      isAvailable: parseBool(map['isAvailable'], true),
      isApproved: parseBool(map['isApproved'], false),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  String get displayName => '$year $make $model';
}
