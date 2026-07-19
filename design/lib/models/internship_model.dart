class InternshipModel {
  final String? id;
  final String userId;
  final String companyName;
  final String position;
  final String? mentorName;
  final String? mentorEmail;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InternshipModel({
    this.id,
    required this.userId,
    required this.companyName,
    required this.position,
    this.mentorName,
    this.mentorEmail,
    required this.startDate,
    required this.endDate,
    this.status = 'Active',
    this.createdAt,
    this.updatedAt,
  });

  factory InternshipModel.fromJson(Map<String, dynamic> json) {
    return InternshipModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      companyName: json['company_name'] as String,
      position: json['position'] as String,
      mentorName: json['mentor_name'] as String?,
      mentorEmail: json['mentor_email'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: (json['status'] ?? 'Active') as String,
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
      if (id != null) 'id': id,
      'user_id': userId,
      'company_name': companyName,
      'position': position,
      if (mentorName != null) 'mentor_name': mentorName,
      if (mentorEmail != null) 'mentor_email': mentorEmail,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  InternshipModel copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? position,
    String? mentorName,
    String? mentorEmail,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InternshipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      mentorName: mentorName ?? this.mentorName,
      mentorEmail: mentorEmail ?? this.mentorEmail,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
