class MedicalRecord {
  final String id;
  final String userId;
  final String title;
  final String extractedText;
  final String imageUrl;
  final DateTime createdAt;
  final String? patientName;
  final String? hospitalName;
  final List<String> medicines;
  final String? recordDate;
  final String? diagnosis;
  final String? patientAge;
  final String? patientGender;

  MedicalRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.extractedText,
    required this.imageUrl,
    required this.createdAt,
    this.patientName,
    this.hospitalName,
    this.medicines = const [],
    this.recordDate,
    this.diagnosis,
    this.patientAge,
    this.patientGender,
  });

  /// Factory constructor to create a MedicalRecord from a Map
  factory MedicalRecord.fromMap(String id, Map<String, dynamic> data) {
    return MedicalRecord(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled Record',
      extractedText: data['extractedText'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : DateTime.now(),
      patientName: data['patientName'],
      hospitalName: data['hospitalName'],
      medicines: data['medicines'] != null ? List<String>.from(data['medicines']) : [],
      recordDate: data['recordDate'],
      diagnosis: data['diagnosis'],
      patientAge: data['patientAge'],
      patientGender: data['patientGender'],
    );
  }

  /// Convert a MedicalRecord into a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'extractedText': extractedText,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (patientName != null) 'patientName': patientName,
      if (hospitalName != null) 'hospitalName': hospitalName,
      'medicines': medicines,
      if (recordDate != null) 'recordDate': recordDate,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (patientAge != null) 'patientAge': patientAge,
      if (patientGender != null) 'patientGender': patientGender,
    };
  }
}
