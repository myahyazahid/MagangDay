class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String nim;
  final String university;
  final String studyProgram;
  final int semester;
  final String? profilePhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.nim,
    required this.university,
    required this.studyProgram,
    required this.semester,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      nim: (json['nim'] ?? '') as String,
      university: (json['university'] ?? '') as String,
      studyProgram: (json['study_program'] ?? '') as String,
      semester: (json['semester'] ?? 1) as int,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'nim': nim,
      'university': university,
      'study_program': studyProgram,
      'semester': semester,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? nim,
    String? university,
    String? studyProgram,
    int? semester,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      nim: nim ?? this.nim,
      university: university ?? this.university,
      studyProgram: studyProgram ?? this.studyProgram,
      semester: semester ?? this.semester,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
