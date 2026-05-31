class PrescriptionModel {
  final int id;
  final int consultation;
  final int doctor;
  final String doctorName;
  final int patient;
  final String patientName;
  final String medication;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;
  final String createdAt;

  PrescriptionModel({
    required this.id,
    required this.consultation,
    required this.doctor,
    required this.doctorName,
    required this.patient,
    required this.patientName,
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      consultation: json['consultation'],
      doctor: json['doctor'],
      doctorName: json['doctor_name'] ?? '',
      patient: json['patient'],
      patientName: json['patient_name'] ?? '',
      medication: json['medication'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
