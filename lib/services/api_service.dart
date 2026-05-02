import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl =
      'https://hand-sign-detection-production.up.railway.app';

  // 🔥 Increased timeout
  static const int _frameTimeoutSeconds = 15;

  // 🔥 Prevent parallel requests
  static bool _isSending = false;

  static Future<Map<String, dynamic>?> predictFrame({
    required List<int> jpegBytes,
    required String userId,
  }) async {
    // 🚨 Skip if previous request still running
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

      final streamed = await request.send().timeout(
        const Duration(seconds: _frameTimeoutSeconds),
      );

      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'prediction': body['prediction'] ?? 'Detecting...',
          'hand_visible': body['hand_visible'] ?? false,
          'buffer_ready': body['buffer_ready'] ?? false,
          'frame_count': body['frame_count'] ?? 0,
        };
      } else {
        print("ERROR ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR in predictFrame: $e");
      return null;
    } finally {
      _isSending = false; // ✅ always reset
    }
  }

  // RESET
  static Future<void> resetSession(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/reset-session');
      await http.post(uri, body: {'user_id': userId});
    } catch (e) {
      print("resetSession error: $e");
    }
  }

  // HEALTH CHECK
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}