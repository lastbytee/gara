import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/intake.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class IntakeProvider extends ChangeNotifier {
  List<IntakeModel> _intakes = [];
  IntakeModel? _currentIntake;
  bool _loading = false;
  String? _error;

  List<IntakeModel> get intakes => _intakes;
  IntakeModel? get currentIntake => _currentIntake;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> createIntake({
    required String sex,
    required String severity,
    required String duration,
    required String symptomsDescription,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('IntakeProvider: POST to ${ApiConfig.createIntake}');
      final data = await ApiService.post(ApiConfig.createIntake, body: {
        'sex': sex,
        'severity': severity,
        'duration': duration,
        'symptoms_description': symptomsDescription,
      });
      debugPrint('IntakeProvider: success — $data');
      _currentIntake = IntakeModel.fromJson(data);
      _intakes.insert(0, _currentIntake!);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('IntakeProvider: ApiException — ${e.message}');
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('IntakeProvider: Exception — $e');
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        _error = 'Server took too long to respond. Try again.';
      } else if (msg.contains('SocketException') || msg.contains('HandshakeException')) {
        _error = 'Cannot reach server. Check your connection.';
      } else if (msg.contains('FormatException')) {
        _error = 'Invalid server response. Check backend logs.';
      } else {
        _error = 'Connection error: ${e.runtimeType}';
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyIntakes() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.get(ApiConfig.myIntakes);
      _intakes = (data['results'] as List? ?? [])
          .map((e) => IntakeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void setCurrentIntake(IntakeModel intake) {
    _currentIntake = intake;
    notifyListeners();
  }
}
