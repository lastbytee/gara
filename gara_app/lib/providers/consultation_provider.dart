import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';
import '../config/api_config.dart';

class ConsultationProvider extends ChangeNotifier {
  List<ConsultationModel> _consultations = [];
  List<MessageModel> _messages = [];
  ConsultationModel? _currentConsultation;
  bool _loading = false;

  List<ConsultationModel> get consultations => _consultations;
  List<MessageModel> get messages => _messages;
  ConsultationModel? get currentConsultation => _currentConsultation;
  bool get loading => _loading;

  ConsultationModel? _activeWithPatient(int patientId) {
    try {
      return _consultations.firstWhere(
        (c) => c.patient == patientId && c.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> createConsultation(int patientId, {int? intakeId}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.post(ApiConfig.createConsultation, body: {
        'patient_id': patientId,
        'intake_id': intakeId,
      });
      final consultation = ConsultationModel.fromJson(data);
      _consultations.insert(0, consultation);
      _currentConsultation = consultation;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyConsultations() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.get(ApiConfig.myConsultations);
      _consultations = (data['results'] as List? ?? [])
          .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(int consultationId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.get(ApiConfig.consultationMessages(consultationId));
      _messages = (data['results'] as List? ?? [])
          .map((e) {
            final msg = e as Map<String, dynamic>;
            if (msg['message_type'] == 'TEXT' && msg['text_content'] != null) {
              msg['text_content'] = EncryptionService.decrypt(msg['text_content'], consultationId);
            }
            return MessageModel.fromJson(msg);
          })
          .toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> sendTextMessage(int consultationId, String text) async {
    try {
      final encrypted = EncryptionService.encrypt(text, consultationId);
      final data = await ApiService.post(ApiConfig.sendMessage(consultationId), body: {
        'message_type': 'TEXT',
        'text_content': encrypted,
      });
      _messages.add(MessageModel.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendAudioMessage(int consultationId, File audioFile) async {
    try {
      final bytes = await audioFile.readAsBytes();
      final data = await ApiService.uploadBytes(
        ApiConfig.sendMessage(consultationId),
        bytes: bytes,
        filename: audioFile.path.split('/').last.split('\\').last,
        fieldName: 'audio_file',
        fields: {'message_type': 'AUDIO'},
      );
      _messages.add(MessageModel.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendAudioBytes(int consultationId, Uint8List bytes, String filename) async {
    try {
      final data = await ApiService.uploadBytes(
        ApiConfig.sendMessage(consultationId),
        bytes: bytes,
        filename: filename,
        fieldName: 'audio_file',
        fields: {'message_type': 'AUDIO'},
      );
      _messages.add(MessageModel.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendImageMessage(int consultationId, Uint8List bytes, String filename) async {
    try {
      final data = await ApiService.uploadBytes(
        ApiConfig.sendMessage(consultationId),
        bytes: bytes,
        filename: filename,
        fieldName: 'image_file',
        fields: {'message_type': 'IMAGE'},
      );
      _messages.add(MessageModel.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ConsultationModel?> getOrCreateConsultation(int patientId) async {
    await fetchMyConsultations();
    final existing = _activeWithPatient(patientId);
    if (existing != null) {
      _currentConsultation = existing;
      notifyListeners();
      return existing;
    }
    final success = await createConsultation(patientId);
    return success ? _currentConsultation : null;
  }

  Future<bool> updateStatus(int consultationId, String status) async {
    try {
      await ApiService.patch(ApiConfig.updateStatus(consultationId), body: {'status': status});
      await fetchMyConsultations();
      return true;
    } catch (e) {
      return false;
    }
  }

  void setCurrentConsultation(ConsultationModel consultation) {
    _currentConsultation = consultation;
    notifyListeners();
  }

  List<ConsultationModel> get activeConsultations =>
      _consultations.where((c) => c.isActive).toList();
}
