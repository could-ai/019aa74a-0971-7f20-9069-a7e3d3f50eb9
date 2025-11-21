import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_model.dart';
import 'package:uuid/uuid.dart';

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<WordItem?> fetchWordDefinition(String word) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$word'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final entry = data[0];
          final String wordText = entry['word'];
          
          // Get phonetic
          String phonetic = '';
          if (entry['phonetic'] != null) {
            phonetic = entry['phonetic'];
          } else if (entry['phonetics'] != null && (entry['phonetics'] as List).isNotEmpty) {
            for (var p in entry['phonetics']) {
              if (p['text'] != null) {
                phonetic = p['text'];
                break;
              }
            }
          }

          // Get audio
          String? audioUrl;
          if (entry['phonetics'] != null) {
            for (var p in entry['phonetics']) {
              if (p['audio'] != null && p['audio'].toString().isNotEmpty) {
                audioUrl = p['audio'];
                break;
              }
            }
          }

          // Get first definition
          String definition = 'No definition found';
          if (entry['meanings'] != null && (entry['meanings'] as List).isNotEmpty) {
            final meanings = entry['meanings'] as List;
            for (var meaning in meanings) {
              if (meaning['definitions'] != null && (meaning['definitions'] as List).isNotEmpty) {
                definition = meaning['definitions'][0]['definition'];
                break;
              }
            }
          }

          return WordItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generation
            word: wordText,
            definition: definition,
            phonetic: phonetic,
            audioUrl: audioUrl,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('Error fetching definition: $e');
    }
    return null;
  }
}
