class UserProfile {
  final String uid;
  final String name;
  final String photoUrl;
  final String age;
  final String gender;
  
  // Vitals
  final String height; // in cm
  final String weight; // in kg
  final String bloodType;
  
  // Clinical
  final String allergies;
  final String conditions;
  final String currentMedications;
  final String primaryPhysician;
  
  // Emergency
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool isOrganDonor;

  UserProfile({
    required this.uid,
    this.name = '',
    this.photoUrl = '',
    this.age = '',
    this.gender = '',
    this.height = '',
    this.weight = '',
    this.bloodType = '',
    this.allergies = '',
    this.conditions = '',
    this.currentMedications = '',
    this.primaryPhysician = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.isOrganDonor = false,
  });

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? age,
    String? gender,
    String? height,
    String? weight,
    String? bloodType,
    String? allergies,
    String? conditions,
    String? currentMedications,
    String? primaryPhysician,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isOrganDonor,
  }) {
    return UserProfile(
      uid: this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      currentMedications: currentMedications ?? this.currentMedications,
      primaryPhysician: primaryPhysician ?? this.primaryPhysician,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      height: data['height'] ?? '',
      weight: data['weight'] ?? '',
      bloodType: data['bloodType'] ?? '',
      allergies: data['allergies'] ?? '',
      conditions: data['conditions'] ?? '',
      currentMedications: data['currentMedications'] ?? '',
      primaryPhysician: data['primaryPhysician'] ?? '',
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '',
      isOrganDonor: data['isOrganDonor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'allergies': allergies,
      'conditions': conditions,
      'currentMedications': currentMedications,
      'primaryPhysician': primaryPhysician,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'isOrganDonor': isOrganDonor,
    };
  }
}
