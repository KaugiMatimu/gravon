enum BookingStatus { pending, confirmed, cancelled, completed }

class BookingModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImageUrl;
  final String tenantId;
  final String landlordId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImageUrl,
    required this.tenantId,
    required this.landlordId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyImageUrl': propertyImageUrl,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      propertyId: map['propertyId'] ?? '',
      propertyTitle: map['propertyTitle'] ?? '',
      propertyImageUrl: map['propertyImageUrl'] ?? '',
      tenantId: map['tenantId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
