import '../../models/user.dart' as dto;
import '../models/user.dart' as domain;

/// Converts user-related DTOs into domain models.
///
/// The UI layer never imports [dto] directly — it only sees [domain] models
/// returned by repositories that call these mappers internally.
abstract final class UserMapper {
  /// [dto.UserBrief] → [domain.User]
  static domain.User fromBriefDto(dto.UserBrief d) {
    return domain.User(
      id: d.id,
      username: d.username,
      role: _parseRole(d.role),
      currentBook: d.currentBook,
    );
  }

  /// [dto.TeacherBrief] → [domain.User]
  static domain.User fromTeacherDto(dto.TeacherBrief d) {
    return domain.User(
      id: d.id,
      username: d.username,
      role: domain.UserRole.teacher,
    );
  }

  /// [dto.StudentInfo] → [domain.StudentSummary]
  static domain.StudentSummary fromStudentInfoDto(dto.StudentInfo d) {
    return domain.StudentSummary(
      id: d.id,
      username: d.username,
      createdAt: d.createdAt,
      totalQuizzes: d.totalQuizzes,
      avgScore: d.avgScore,
      bestScore: d.bestScore,
      totalWordsTested: d.totalWordsTested,
    );
  }

  static domain.UserRole _parseRole(String role) {
    return role == 'teacher' ? domain.UserRole.teacher : domain.UserRole.student;
  }
}
