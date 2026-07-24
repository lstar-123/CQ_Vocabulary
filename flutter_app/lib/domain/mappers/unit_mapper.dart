import '../../models/unit.dart' as dto;
import '../models/unit.dart' as domain;
import 'word_mapper.dart';

abstract final class UnitMapper {
  static domain.Unit fromBriefDto(dto.UnitBrief d) {
    return domain.Unit(
      id: d.id,
      name: d.name,
      wordCount: d.wordCount,
    );
  }

  static domain.UnitWithWords fromUnitWithWordsDto(dto.UnitWithWords d) {
    return domain.UnitWithWords(
      id: d.unitId,
      name: d.unitName,
      orderNum: d.orderNum,
      words: d.words.map(WordMapper.fromBriefDto).toList(growable: false),
    );
  }
}
