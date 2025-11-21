import 'dart:convert';

class WordItem {
  final String id;
  final String word;
  final String definition;
  final String phonetic;
  final String? audioUrl;
  final DateTime timestamp;

  WordItem({
    required this.id,
    required this.word,
    required this.definition,
    required this.phonetic,
    this.audioUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'phonetic': phonetic,
      'audioUrl': audioUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      id: json['id'],
      word: json['word'],
      definition: json['definition'],
      phonetic: json['phonetic'] ?? '',
      audioUrl: json['audioUrl'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
