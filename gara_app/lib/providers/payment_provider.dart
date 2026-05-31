import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentModel> _myPayments = [];
  List<PaymentModel> _pendingPayments = [];
  double _dailyRevenue = 0;
  int _approvedCount = 0;
  bool _loading = false;
  String? _error;

  List<PaymentModel> get myPayments => _myPayments;
  List<PaymentModel> get pendingPayments => _pendingPayments;
  double get dailyRevenue => _dailyRevenue;
  int get approvedCount => _approvedCount;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> createPayment({
    required double amount,
    required Uint8List screenshotBytes,
    String? senderPhone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.uploadBytes(
        ApiConfig.createPayment,
        bytes: screenshotBytes,
        fieldName: 'screenshot',
        filename: 'payment.jpg',
        fields: {
          'amount': amount.toString(),
          if (senderPhone != null && senderPhone.isNotEmpty)
            'sender_phone': senderPhone,
        },
      );
      _myPayments.insert(0, PaymentModel.fromJson(data));
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

  Future<void> fetchMyPayments() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.get(ApiConfig.myPayments);
      _myPayments = (data['results'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchPendingPayments() async {
    try {
      final data = await ApiService.get(ApiConfig.pendingPayments);
      _pendingPayments = (data['results'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> reviewPayment(int paymentId, String status, {String? notes}) async {
    try {
      final data = await ApiService.post(
        ApiConfig.reviewPayment(paymentId),
        body: {'status': status, 'doctor_notes': notes ?? ''},
      );
      await fetchPendingPayments();
      await fetchDailyRevenue();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchDailyRevenue() async {
    try {
      final data = await ApiService.get(ApiConfig.dailyRevenue);
      _dailyRevenue = double.parse(data['total_revenue'].toString());
      _approvedCount = data['approved_count'] as int? ?? 0;
      notifyListeners();
    } catch (_) {}
  }
}
