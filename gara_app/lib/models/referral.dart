class ReferralModel {
  final int id;
  final int consultation;
  final int doctor;
  final String doctorName;
  final int patient;
  final String patientName;
  final String priority;
  final String referralReason;
  final String referredTo;
  final String? notes;
  final String createdAt;

  ReferralModel({
    required this.id,
    required this.consultation,
    required this.doctor,
    required this.doctorName,
    required this.patient,
    required this.patientName,
    required this.priority,
    required this.referralReason,
    required this.referredTo,
    this.notes,
    required this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'],
      consultation: json['consultation'],
      doctor: json['doctor'],
      doctorName: json['doctor_name'] ?? '',
      patient: json['patient'],
      patientName: json['patient_name'] ?? '',
      priority: json['priority'] ?? 'STANDARD',
      referralReason: json['referral_reason'] ?? '',
      referredTo: json['referred_to'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
