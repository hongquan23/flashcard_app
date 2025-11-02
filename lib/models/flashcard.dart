// models/flashcard.dart
class Flashcard {
  final String term;
  final String meaning;
  final String? note;
  final String? imagePath; // ĐƯỜNG DẪN ẢNH

  Flashcard({
    required this.term,
    required this.meaning,
    this.note,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'meaning': meaning,
    'note': note,
    'imagePath': imagePath,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    term: json['term'],
    meaning: json['meaning'],
    note: json['note'],
    imagePath: json['imagePath'],
  );
}