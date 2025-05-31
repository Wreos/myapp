class CVFeedback {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime createdAt;

  const CVFeedback({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CVFeedback.fromJson(Map<String, dynamic> json) {
    return CVFeedback(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CVData {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final List<CVFeedback>? feedback;
  final DateTime uploadedAt;
  final DateTime? lastAnalyzedAt;

  const CVData({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    this.feedback,
    required this.uploadedAt,
    this.lastAnalyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'feedback': feedback?.map((f) => f.toJson()).toList(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'lastAnalyzedAt': lastAnalyzedAt?.toIso8601String(),
    };
  }

  factory CVData.fromJson(Map<String, dynamic> json) {
    return CVData(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] as int?,
      feedback: (json['feedback'] as List<dynamic>?)
          ?.map((e) => CVFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      lastAnalyzedAt: json['lastAnalyzedAt'] != null
          ? DateTime.parse(json['lastAnalyzedAt'] as String)
          : null,
    );
  }

  static CVData fromFirestore(Map<String, dynamic> data, String id) {
    return CVData.fromJson({
      ...data,
      'id': id,
    });
  }

  CVData copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    List<CVFeedback>? feedback,
    DateTime? uploadedAt,
    DateTime? lastAnalyzedAt,
  }) {
    return CVData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      feedback: feedback ?? this.feedback,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastAnalyzedAt: lastAnalyzedAt ?? this.lastAnalyzedAt,
    );
  }
}
