class CareerGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final double progress;
  final List<String>? milestones;
  final String? notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CareerGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    this.progress = 0.0,
    this.milestones,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'progress': progress,
      'milestones': milestones,
      'notes': notes,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CareerGoal.fromJson(Map<String, dynamic> json) {
    return CareerGoal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      milestones: (json['milestones'] as List<dynamic>?)?.cast<String>(),
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  static CareerGoal fromFirestore(Map<String, dynamic> data, String id) {
    return CareerGoal.fromJson({
      ...data,
      'id': id,
    });
  }

  CareerGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    double? progress,
    List<String>? milestones,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareerGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      milestones: milestones ?? this.milestones,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
