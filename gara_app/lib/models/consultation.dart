class ConsultationModel {
  final int id;
  final int patient;
  final String patientName;
  final int doctor;
  final String doctorName;
  final int? intake;
  final String status;
  final String createdAt;
  final String updatedAt;

  ConsultationModel({
    required this.id,
    required this.patient,
    required this.patientName,
    required this.doctor,
    required this.doctorName,
    this.intake,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      patient: json['patient'],
      patientName: json['patient_name'] ?? '',
      doctor: json['doctor'],
      doctorName: json['doctor_name'] ?? '',
      intake: json['intake'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isResolved => status == 'RESOLVED';
  bool get isReferred => status == 'REFERRED';
}

class MessageModel {
  final int id;
  final int consultation;
  final int sender;
  final String senderName;
  final String messageType;
  final String? textContent;
  final String? audioFile;
  final String? imageFile;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.consultation,
    required this.sender,
    required this.senderName,
    required this.messageType,
    this.textContent,
    this.audioFile,
    this.imageFile,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      consultation: json['consultation'],
      sender: json['sender'],
      senderName: json['sender_name'] ?? '',
      messageType: json['message_type'] ?? 'TEXT',
      textContent: json['text_content'],
      audioFile: json['audio_file'],
      imageFile: json['image_file'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isText => messageType == 'TEXT';
  bool get isAudio => messageType == 'AUDIO';
  bool get isImage => messageType == 'IMAGE';

  Map<String, dynamic> toJson() => {
    'id': id,
    'consultation': consultation,
    'sender': sender,
    'sender_name': senderName,
    'message_type': messageType,
    'text_content': textContent,
    'audio_file': audioFile,
    'image_file': imageFile,
    'created_at': createdAt,
  };
}
