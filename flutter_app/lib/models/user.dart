/// User-related DTOs mapped from backend API responses.
///
/// Backend sources:
///   - POST /api/auth/register → UserBrief
///   - POST /api/auth/login    → UserBrief
///   - GET  /api/auth/me       → UserBrief (student) or TeacherBrief
///   - GET  /api/teacher/students → StudentInfo
library;

/// Returned by auth endpoints: register, login, /me (student).
class UserBrief {
  const UserBrief({
    required this.id,
    required this.username,
    required this.role,
    this.currentBook,
  });

  final int id;
  final String username;
  final String role; // "student" | "teacher"
  final String? currentBook;

  factory UserBrief.fromJson(Map<String, dynamic> json) {
    return UserBrief(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      currentBook: json['current_book'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'current_book': currentBook,
    };
  }
}

/// Returned by GET /api/auth/me (teacher).
class TeacherBrief {
  const TeacherBrief({
    required this.id,
    required this.username,
  });

  final int id;
  final String username;
  static const String role = 'teacher';

  factory TeacherBrief.fromJson(Map<String, dynamic> json) {
    return TeacherBrief(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }
}

/// Returned by GET /api/teacher/students.
class StudentInfo {
  const StudentInfo({
    required this.id,
    required this.username,
    this.createdAt,
    required this.totalQuizzes,
    required this.avgScore,
    required this.bestScore,
    required this.totalWordsTested,
  });

  final int id;
  final String username;
  final String? createdAt;
  final int totalQuizzes;
  final double avgScore;
  final double bestScore;
  final int totalWordsTested;

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      createdAt: json['created_at'] as String?,
      totalQuizzes: json['total_quizzes'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      bestScore: (json['best_score'] as num?)?.toDouble() ?? 0.0,
      totalWordsTested: json['total_words_tested'] as int? ?? 0,
    );
  }
}

/// Request body for register.
class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.password,
    this.bookSchema,
  });

  final String username;
  final String password;
  final String? bookSchema;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (bookSchema != null) 'book_schema': bookSchema,
    };
  }
}

/// Request body for login (student & teacher).
class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
