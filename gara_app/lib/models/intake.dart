class IntakeModel {
  final int id;
  final int patient;
  final String? sex;
  final String? severity;
  final String? duration;
  final String? symptomsDescription;
  final String? aiClinicalSummary;
  final bool isSubmitted;
  final String createdAt;
  final String paymentStatus; // "none", "pending", "approved", "rejected"

  IntakeModel({
    required this.id,
    required this.patient,
    this.sex,
    this.severity,
    this.duration,
    this.symptomsDescription,
    this.aiClinicalSummary,
    this.isSubmitted = false,
    required this.createdAt,
    this.paymentStatus = 'none',
  });

  bool get hasPaid => paymentStatus == 'approved';

  factory IntakeModel.fromJson(Map<String, dynamic> json) {
    return IntakeModel(
      id: json['id'],
      patient: json['patient'],
      sex: json['sex'],
      severity: json['severity'],
      duration: json['duration'],
      symptomsDescription: json['symptoms_description'],
      aiClinicalSummary: json['ai_clinical_summary'],
      isSubmitted: json['is_submitted'] ?? false,
      createdAt: json['created_at'] ?? '',
      paymentStatus: json['payment_status'] ?? 'none',
    );
  }
}
