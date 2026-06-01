class PaymentModel {
  final int id;
  final int patient;
  final String patientName;
  final double amount;
  final String? screenshot;
  final String? senderPhone;
  final String status;
  final String? doctorNotes;
  final String createdAt;
  final String? approvedAt;
  final String? doctorName;
  final String? doctorMomoPhone;
  final String? doctorMomoNetwork;

  PaymentModel({
    required this.id,
    required this.patient,
    required this.patientName,
    required this.amount,
    this.screenshot,
    this.senderPhone,
    required this.status,
    this.doctorNotes,
    required this.createdAt,
    this.approvedAt,
    this.doctorName,
    this.doctorMomoPhone,
    this.doctorMomoNetwork,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      patient: json['patient'],
      patientName: json['patient_name'] ?? '',
      amount: double.parse(json['amount'].toString()),
      screenshot: json['screenshot'],
      senderPhone: json['sender_phone'],
      status: json['status'] ?? 'PENDING',
      doctorNotes: json['doctor_notes'],
      createdAt: json['created_at'] ?? '',
      approvedAt: json['approved_at'],
      doctorName: json['doctor_name'],
      doctorMomoPhone: json['doctor_momo_phone'],
      doctorMomoNetwork: json['doctor_momo_network'],
    );
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
}
