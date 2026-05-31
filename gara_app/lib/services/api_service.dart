import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const _timeout = Duration(seconds: 30);
  static String? _accessToken;
  static String? _refreshToken;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static bool get isLoggedIn => _accessToken != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers).timeout(_timeout);
    return _handle(response, 'GET');
  }

  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handle(response, 'POST', body: body);
  }

  static Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handle(response, 'PATCH', body: body);
  }

  static Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required Uint8List bytes,
    String fieldName = 'file',
    String filename = 'upload',
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response, 'POST', body: fields);
  }

  static Future<Map<String, dynamic>> _handle(
    http.Response response,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is List) {
        return <String, dynamic>{'results': decoded};
      }
      return decoded as Map<String, dynamic>;
    }

    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final url = response.request?.url.toString() ?? '';
        http.Response retryResponse;
        final retryHeaders = _headers;
        if (method == 'GET') {
          retryResponse = await http.get(Uri.parse(url), headers: retryHeaders).timeout(_timeout);
        } else if (method == 'PATCH') {
          retryResponse = await http.patch(Uri.parse(url), headers: retryHeaders, body: body != null ? jsonEncode(body) : null).timeout(_timeout);
        } else {
          retryResponse = await http.post(Uri.parse(url), headers: retryHeaders, body: body != null ? jsonEncode(body) : null).timeout(_timeout);
        }
        final retryDecoded = retryResponse.body.isNotEmpty
            ? jsonDecode(retryResponse.body)
            : <String, dynamic>{};
        if (retryDecoded is List) {
          return <String, dynamic>{'results': retryDecoded};
        }
        return retryDecoded as Map<String, dynamic>;
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: data['detail']?.toString() ?? data.toString(),
    );
  }

  static Future<bool> _tryRefresh() async {
    try {
      final response = await http.post(
        _uri(ApiConfig.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], _refreshToken!);
        return true;
      }
      clearTokens();
      return false;
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
