import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.100:5000';
  static const String predictEndpoint = '/upload';
  static const int timeoutDuration = 30;

  /// Sends an image to the backend for gesture prediction
  /// Returns a map containing prediction results
  static Future<Map<String, dynamic>> predictGesture(List<int> imageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl$predictEndpoint');

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'gesture.jpg',
          ),
        );

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: timeoutDuration),
            onTimeout: () {
              throw Exception('Request timeout: prediction took too long');
            },
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else {
        throw Exception(
          'Failed to predict gesture: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      throw Exception('Error predicting gesture: $e');
    }
  }

  /// Checks if the backend server is available
  static Future<bool> checkServerHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Health check timeout');
            },
          );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
