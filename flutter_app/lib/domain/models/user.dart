/// Domain models for authentication and user identity.
///
/// These are the stable, UI-facing representations. They are NEVER
/// constructed from JSON directly — [UserMapper] handles DTO conversion.
library;

enum UserRole { student, teacher }

/// The authenticated user's identity, derived from /api/auth/me or login responses.
class User {
  const User({
    required this.id,
    required this.username,
    required this.role,
    this.currentBook,
  });

  final int id;
  final String username;
  final UserRole role;
  final String? currentBook;

  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;
}

/// A student's summary info (teacher dashboard).
class StudentSummary {
  const StudentSummary({
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
}
