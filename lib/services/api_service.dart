import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://hand-sign-detection-production.up.railway.app';
  // static const String baseUrl = 'http://127.0.0.1:8000';

  static bool _isSending = false;

  static Future<Map<String, dynamic>?> predictFrame({
    required List<int> jpegBytes,
    required String userId,
  }) async {
    if (_isSending) return null;

    _isSending = true;

    try {
      final uri = Uri.parse('$baseUrl/predict-frame');

      final request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            jpegBytes,
            filename: 'frame.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        return {
          'prediction': body['prediction'] ?? '',
          'hand_visible': body['hand_visible'] ?? false,
          'buffer_ready': body['buffer_ready'] ?? false,
          'frame_count': body['frame_count'] ?? 0,
        };
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("API error: $e");
    } finally {
      _isSending = false;
    }


    return null;
    }

  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'ok';
      }
    } catch (e) {
      print("Health check error: $e");
    }

    return false;
  }
  }
