class IntakeModel {
  final int id;
  final int patient;
  final String sex;
  final String severity;
  final String duration;
  final String symptomsDescription;
  final String? aiClinicalSummary;
  final bool isSubmitted;
  final String createdAt;

  IntakeModel({
    required this.id,
    required this.patient,
    required this.sex,
    required this.severity,
    required this.duration,
    required this.symptomsDescription,
    this.aiClinicalSummary,
    this.isSubmitted = false,
    required this.createdAt,
  });

  factory IntakeModel.fromJson(Map<String, dynamic> json) {
    return IntakeModel(
      id: json['id'],
      patient: json['patient'],
      sex: json['sex'],
      severity: json['severity'],
      duration: json['duration'],
      symptomsDescription: json['symptoms_description'] ?? '',
      aiClinicalSummary: json['ai_clinical_summary'],
      isSubmitted: json['is_submitted'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
