import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/song.dart';

class NCTService {
  static final _logger = Logger('NCTService');
  static const String _baseUrl = 'https://api.nhaccuatui.com/v1';
  static const String _searchEndpoint = '/search';
  static const int _perPage = 20;

  final http.Client _client;

  NCTService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Song>> searchSongs(String query, {int page = 1}) async {
    try {
      final uri = Uri.parse('$_baseUrl$_searchEndpoint').replace(
        queryParameters: {
          'q': query,
          'page': page.toString(),
          'per_page': _perPage.toString(),
          'type': 'song',
        },
      );

      _logger.fine('Searching NCT with URI: $uri');

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSearchResults(data);
      } else {
        _logger.warning('NCT API returned status code: ${response.statusCode}');
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      _logger.severe('Error searching NCT: $e');
      rethrow;
    }
  }

  List<Song> _parseSearchResults(Map<String, dynamic> data) {
    try {
      final List<dynamic> songs = data['data']?['songs'] ?? [];
      return songs.map<Song>((song) {
        return Song(
          title: song['title'] ?? 'Unknown Title',
          artist:
              song['artists']?.map((a) => a['name']).join(', ') ??
              'Unknown Artist',
          path: song['streaming']?['mp3']?['128'] ?? '',
          album: song['album']?['title'] ?? 'Unknown Album',
          duration: song['duration'] != null
              ? Duration(seconds: song['duration'])
              : Duration.zero,
          albumArt: song['thumbnail'],
          genre: song['genres']?.firstOrNull?['name'],
          year: song['release_date'] != null
              ? DateTime.parse(song['release_date']).year
              : null,
        );
      }).toList();
    } catch (e) {
      _logger.severe('Error parsing NCT search results: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
