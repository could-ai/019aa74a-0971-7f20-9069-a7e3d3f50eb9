import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import '../services/dictionary_service.dart';

class ClipboardProvider with ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  List<WordItem> _words = [];
  bool _isMonitoring = false;
  Timer? _timer;
  String? _lastClipboardContent;

  List<WordItem> get words => _words;
  bool get isMonitoring => _isMonitoring;

  ClipboardProvider() {
    _loadWords();
  }

  Future<void> _loadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? wordsJson = prefs.getString('saved_words');
    if (wordsJson != null) {
      final List<dynamic> decoded = json.decode(wordsJson);
      _words = decoded.map((item) => WordItem.fromJson(item)).toList();
      // Sort by newest first
      _words.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_words.map((w) => w.toJson()).toList());
    await prefs.setString('saved_words', encoded);
  }

  void toggleMonitoring() {
    _isMonitoring = !_isMonitoring;
    if (_isMonitoring) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
    notifyListeners();
  }

  void _startMonitoring() {
    // Poll clipboard every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkClipboard();
    });
  }

  void _stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final String content = data.text!.trim();
      
      // Basic validation: ignore if empty, same as last, or too long (likely a sentence/paragraph)
      if (content.isNotEmpty && 
          content != _lastClipboardContent && 
          !content.contains(' ') && // Only single words
          content.length < 30) { // Reasonable word length limit
        
        _lastClipboardContent = content;
        
        // Check if we already have this word to avoid duplicates
        final bool exists = _words.any((w) => w.word.toLowerCase() == content.toLowerCase());
        if (!exists) {
          await _fetchAndAddWord(content);
        }
      }
    }
  }

  Future<void> _fetchAndAddWord(String word) async {
    final WordItem? newItem = await _dictionaryService.fetchWordDefinition(word);
    if (newItem != null) {
      _words.insert(0, newItem); // Add to top
      await _saveWords();
      notifyListeners();
    }
  }

  Future<void> deleteWord(String id) async {
    _words.removeWhere((w) => w.id == id);
    await _saveWords();
    notifyListeners();
  }
  
  Future<void> clearAll() async {
    _words.clear();
    await _saveWords();
    notifyListeners();
  }
  
  // Manual add for testing or user input
  Future<void> manualAddWord(String word) async {
    if (word.trim().isEmpty) return;
    await _fetchAndAddWord(word.trim());
  }
}
