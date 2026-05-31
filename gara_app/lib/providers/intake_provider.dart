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
      final data = await ApiService.post(ApiConfig.createIntake, body: {
        'sex': sex,
        'severity': severity,
        'duration': duration,
        'symptoms_description': symptomsDescription,
      });
      _currentIntake = IntakeModel.fromJson(data);
      _intakes.insert(0, _currentIntake!);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error.';
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
