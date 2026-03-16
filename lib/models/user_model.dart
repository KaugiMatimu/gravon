import '../utils/constants.dart';

enum UserRole { investor, tenant, admin, agent, none }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final bool isAdmin;

  final List<String> likedProperties;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.isAdmin = false,
    this.likedProperties = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'isAdmin': isAdmin,
      'likedProperties': likedProperties,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final String email = map['email'] ?? '';
    final bool isEmailAdmin = AppConstants.adminEmails.contains(email.toLowerCase());
    String roleStr = map['role'] ?? 'none';

    // For backward compatibility with existing 'landlord' roles in database
    if (roleStr == 'landlord') {
      roleStr = 'investor';
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: email,
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleStr,
        orElse: () => UserRole.none,
      ),
      profileImageUrl: map['profileImageUrl'],
      // Admin if: isAdmin flag is true OR role is admin OR email is in admin list
      isAdmin: (map['isAdmin'] == true) || (roleStr == 'admin') || isEmailAdmin,
      likedProperties: List<String>.from(map['likedProperties'] ?? []),
    );
  }
}
