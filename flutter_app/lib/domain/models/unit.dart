import 'word.dart';

/// A unit within a word book, with its word count.
class Unit {
  const Unit({
    required this.id,
    required this.name,
    required this.wordCount,
  });

  final int id;
  final String name;
  final int wordCount;
}

/// A unit with its full word list (for study mode).
class UnitWithWords {
  const UnitWithWords({
    required this.id,
    required this.name,
    required this.orderNum,
    required this.words,
  });

  final int id;
  final String name;
  final int orderNum;
  final List<Word> words;

  int get wordCount => words.length;
}
