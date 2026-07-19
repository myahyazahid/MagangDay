class ActivityLogModel {
  final String? id;
  final String internshipId;
  final String userId;
  final DateTime activityDate;
  final String title;
  final String? projectName;
  final String? category;
  final String? description;
  final String? startTime;
  final String? endTime;
  final int durationMinutes;
  final List<String> technologies;
  final String status;
  final String? challenges;
  final String? learning;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ActivityLogModel({
    this.id,
    required this.internshipId,
    required this.userId,
    required this.activityDate,
    required this.title,
    this.projectName,
    this.category,
    this.description,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.technologies = const [],
    this.status = 'Completed',
    this.challenges,
    this.learning,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String?,
      internshipId: json['internship_id'] as String,
      userId: json['user_id'] as String,
      activityDate: DateTime.parse(json['activity_date'] as String),
      title: json['title'] as String,
      projectName: json['project_name'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      technologies: json['technologies'] != null 
          ? List<String>.from(json['technologies'] as List) 
          : const [],
      status: (json['status'] ?? 'Completed') as String,
      challenges: json['challenges'] as String?,
      learning: json['learning'] as String?,
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
      'internship_id': internshipId,
      'user_id': userId,
      'activity_date': activityDate.toIso8601String().split('T')[0],
      'title': title,
      if (projectName != null) 'project_name': projectName,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'duration_minutes': durationMinutes,
      'technologies': technologies,
      'status': status,
      if (challenges != null) 'challenges': challenges,
      if (learning != null) 'learning': learning,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ActivityLogModel copyWith({
    String? id,
    String? internshipId,
    String? userId,
    DateTime? activityDate,
    String? title,
    String? projectName,
    String? category,
    String? description,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    List<String>? technologies,
    String? status,
    String? challenges,
    String? learning,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      internshipId: internshipId ?? this.internshipId,
      userId: userId ?? this.userId,
      activityDate: activityDate ?? this.activityDate,
      title: title ?? this.title,
      projectName: projectName ?? this.projectName,
      category: category ?? this.category,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      technologies: technologies ?? this.technologies,
      status: status ?? this.status,
      challenges: challenges ?? this.challenges,
      learning: learning ?? this.learning,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
