/// Phonics breakdown for a word.
class Phonics {
  const Phonics({
    required this.word,
    this.ipa,
    this.arpabet,
    required this.syllables,
  });

  final String word;
  final String? ipa;
  final String? arpabet;
  final List<PhonicsSyllable> syllables;
}

class PhonicsSyllable {
  const PhonicsSyllable({
    required this.text,
    required this.stress,
    required this.segments,
  });

  final String text;
  final int stress;
  final List<PhonicsSegment> segments;
}

class PhonicsSegment {
  const PhonicsSegment({
    required this.text,
    required this.silent,
    required this.rule,
  });

  final String text;
  final bool silent;
  final String rule;

  bool get isPronounced => !silent;
}
