import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '../models/gesture_result.dart';

/// A simple wrapper around the remote inference API.
///
/// The server is expected to expose an endpoint at `$baseUrl/classify` which
/// accepts a multipart POST request containing an image file under the field
/// name `image`. The response is assumed to be JSON with the following
/// structure:
///
/// ```json
/// {
///   "label": "A",
///   "confidence": 0.97
/// }
/// ```
///
/// You can customise the base URL when constructing the service.
class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Sends [imageFile] to the server and returns a parsed [GestureResult].
  Future<GestureResult> classifyImage(File imageFile) async {
    final uri = Uri.parse('$baseUrl/classify');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      filename: basename(imageFile.path),
    ));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw HttpException(
          'Unexpected response code ${streamedResponse.statusCode}');
    }

    final body = await streamedResponse.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return GestureResult.fromJson(data);
  }
}
