class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final String preferredLanguage;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.preferredLanguage = 'en',
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
    );
  }

  String get fullName => '$firstName $lastName'.trim().isNotEmpty
      ? '$firstName $lastName'
      : username;

  bool get isDoctor => role == 'DOCTOR';
  bool get isPatient => role == 'PATIENT';
}
