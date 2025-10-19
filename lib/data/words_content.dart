import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class WordContent {
  final String id;
  final String word;
  final String category;
  final int difficulty;
  final String emoji;
  final bool isStarterWord;

  const WordContent({
    required this.id,
    required this.word,
    required this.category,
    this.difficulty = 1,
    this.emoji = '',
    this.isStarterWord = false,
  });

  factory WordContent.fromJson(Map<String, dynamic> j) => WordContent(
        id: j['id'] as String,
        word: j['word'] as String,
        category: j['category'] as String,
        difficulty: (j['difficulty'] ?? 1) as int,
        emoji: (j['emoji'] ?? '') as String,
        isStarterWord: (j['isStarterWord'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'category': category,
        'difficulty': difficulty,
        'emoji': emoji,
        'isStarterWord': isStarterWord,
      };
}

class WordsRepo {
  WordsRepo._();
  static final WordsRepo instance = WordsRepo._();

  List<WordContent> _all = _seed;
  Map<String, WordContent> _byId = {for (final w in _seed) w.id: w};

  List<WordContent> get all => _all;
  WordContent? findById(String id) => _byId[id];

  Future<void> init({String assetPath = 'assets/words.json'}) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = (jsonDecode(raw) as List)
          .map((e) => WordContent.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      _all = list;
      _byId = {for (final w in _all) w.id: w};
    } catch (_) {
      _all = _seed;
      _byId = {for (final w in _seed) w.id: w};
    }
  }

  Future<void> refreshFromBackend(
      Future<List<WordContent>> Function() fetcher) async {
    final list = await fetcher();
    _all = List.unmodifiable(list);
    _byId = {for (final w in _all) w.id: w};
  }
}

const List<WordContent> _seed = [
  WordContent(
      id: 'w_cat',
      word: 'kat',
      category: 'dyr',
      difficulty: 1,
      emoji: '🐱',
      isStarterWord: true),
  WordContent(
      id: 'w_dog',
      word: 'hund',
      category: 'dyr',
      difficulty: 1,
      emoji: '🐶',
      isStarterWord: true),
  WordContent(
      id: 'w_car', word: 'bil', category: 'ting', difficulty: 2, emoji: '🚗'),
  WordContent(
      id: 'w_bus', word: 'bus', category: 'ting', difficulty: 2, emoji: '🚌'),
  WordContent(
      id: 'w_banana',
      word: 'banan',
      category: 'mad',
      difficulty: 2,
      emoji: '🍌'),
  WordContent(
      id: 'w_apple',
      word: 'æble',
      category: 'mad',
      difficulty: 1,
      emoji: '🍎',
      isStarterWord: true),
];
