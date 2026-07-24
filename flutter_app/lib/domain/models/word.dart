/// A vocabulary word.
class Word {
  const Word({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.english,
    required this.chinese,
  });

  final int id;
  final int unitId;
  final String unitName;
  final String english;
  final String chinese;
}
