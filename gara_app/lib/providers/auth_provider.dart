import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;
  bool _rememberMe = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isDoctor => _user?.isDoctor ?? false;
  bool get isPatient => _user?.isPatient ?? false;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiConfig.login, body: {
        'username': username,
        'password': password,
      });
      await ApiService.saveTokens(data['access'], data['refresh']);

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_username');
      }

      await _fetchUser();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPatient({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiConfig.registerPatient, body: {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'phone_number': phoneNumber ?? '',
        'preferred_language': preferredLanguage ?? 'en',
      });
      await ApiService.saveTokens(data['access'], data['refresh']);
      _user = UserModel.fromJson(data['user']);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDoctor({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String registrationToken,
    String? firstName,
    String? lastName,
    String? licenseNumber,
    String? specialization,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiConfig.registerDoctor, body: {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'registration_token': registrationToken,
        'license_number': licenseNumber ?? '',
        'specialization': specialization ?? '',
      });
      await ApiService.saveTokens(data['access'], data['refresh']);
      _user = UserModel.fromJson(data['user']);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleSignIn(String idToken, {String? preferredLanguage}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiConfig.googleAuth, body: {
        'id_token': idToken,
        if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      });
      await ApiService.saveTokens(data['access'], data['refresh']);
      _user = UserModel.fromJson(data['user']);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.post(ApiConfig.passwordReset, body: {'email': email});
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.post(ApiConfig.passwordResetConfirm, body: {
        'email': email,
        'code': code,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      });
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_username') ?? '';
  }

  Future<void> _fetchUser() async {
    try {
      final data = await ApiService.get(ApiConfig.me);
      _user = UserModel.fromJson(data);
    } catch (_) {}
  }

  Future<void> tryAutoLogin() async {
    await ApiService.init();
    if (ApiService.isLoggedIn) {
      await _fetchUser();
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? preferredLanguage,
    String? dateOfBirth,
    String? sex,
    String? address,
    String? licenseNumber,
    String? specialization,
    String? bio,
    Uint8List? profilePictureBytes,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fields = <String, String>{};
      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (phoneNumber != null) fields['phone_number'] = phoneNumber;
      if (preferredLanguage != null) fields['preferred_language'] = preferredLanguage;
      if (dateOfBirth != null) fields['date_of_birth'] = dateOfBirth;
      if (sex != null) fields['sex'] = sex;
      if (address != null) fields['address'] = address;
      if (licenseNumber != null) fields['license_number'] = licenseNumber;
      if (specialization != null) fields['specialization'] = specialization;
      if (bio != null) fields['bio'] = bio;

      Map<String, dynamic> data;
      if (profilePictureBytes != null) {
        data = await ApiService.uploadBytes(
          ApiConfig.updateProfile,
          bytes: profilePictureBytes,
          fieldName: 'profile_picture',
          filename: 'profile.jpg',
          fields: fields.isEmpty ? null : fields,
          method: 'PATCH',
        );
      } else {
        data = await ApiService.patch(ApiConfig.updateProfile, body: fields);
      }

      _user = UserModel.fromJson(data);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
