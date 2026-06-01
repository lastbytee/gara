class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final String preferredLanguage;

  // Profile fields
  final String? dateOfBirth;
  final String? sex;
  final String? profilePicture;
  final String? address;
  final String? licenseNumber;
  final String? specialization;
  final String? bio;
  final String? momoPhoneNumber;
  final String? momoNetwork;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.preferredLanguage = 'en',
    this.dateOfBirth,
    this.sex,
    this.profilePicture,
    this.address,
    this.licenseNumber,
    this.specialization,
    this.bio,
    this.momoPhoneNumber,
    this.momoNetwork,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'PATIENT',
      preferredLanguage: json['preferred_language'] ?? 'en',
      dateOfBirth: json['date_of_birth'],
      sex: json['sex'],
      profilePicture: json['profile_picture'],
      address: json['address'],
      licenseNumber: json['license_number'],
      specialization: json['specialization'],
      bio: json['bio'],
      momoPhoneNumber: json['momo_phone_number'],
      momoNetwork: json['momo_network'],
    );
  }

  String get fullName => '$firstName $lastName'.trim().isNotEmpty
      ? '$firstName $lastName'
      : username;

  bool get isDoctor => role == 'DOCTOR';
  bool get isPatient => role == 'PATIENT';
}
