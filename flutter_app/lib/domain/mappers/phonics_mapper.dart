import '../../models/phonics.dart' as dto;
import '../models/phonics.dart' as domain;

abstract final class PhonicsMapper {
  static domain.Phonics fromDto(dto.PhonicsData d) {
    return domain.Phonics(
      word: d.word,
      ipa: d.ipa,
      arpabet: d.arpabet,
      syllables: d.syllables.map(_syllable).toList(growable: false),
    );
  }

  static domain.PhonicsSyllable _syllable(dto.PhonicsSyllable s) {
    return domain.PhonicsSyllable(
      text: s.text,
      stress: s.stress,
      segments: s.segments.map(_segment).toList(growable: false),
    );
  }

  static domain.PhonicsSegment _segment(dto.PhonicsSegment s) {
    return domain.PhonicsSegment(
      text: s.text,
      silent: s.silent,
      rule: s.rule,
    );
  }
}
