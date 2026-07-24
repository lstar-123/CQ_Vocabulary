import '../../models/word.dart' as dto;
import '../models/word.dart' as domain;

abstract final class WordMapper {
  static domain.Word fromBriefDto(dto.WordBrief d) {
    return domain.Word(
      id: d.id,
      unitId: d.unitId,
      unitName: d.unitName,
      english: d.english,
      chinese: d.chinese,
    );
  }
}
