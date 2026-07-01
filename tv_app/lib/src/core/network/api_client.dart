import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrls = _buildBaseUrls(baseUrl);

  static String? _lastSuccessfulBaseUrl;

  final http.Client _client;
  final List<String> _baseUrls;

  static String? get lastSuccessfulBaseUrl => _lastSuccessfulBaseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    return _sendWithFallback(
      (baseUrl) => _client
          .get(
            _uri(baseUrl, path, queryParameters),
            headers: _headers(bearerToken),
          )
          .timeout(const Duration(seconds: 4)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    return _sendWithFallback(
      (baseUrl) => _client
          .post(
            _uri(baseUrl, path),
            headers: _headers(bearerToken),
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 4)),
    );
  }

  Uri _uri(
    String baseUrl,
    String path, [
    Map<String, String>? queryParameters,
  ]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  Map<String, String> _headers(String? bearerToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
    };
  }

  Future<Map<String, dynamic>> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) send,
  ) async {
    Object? lastError;

    for (final baseUrl in _baseUrls) {
      try {
        final response = await send(baseUrl);
        final decodedResponse = _decodeResponse(response);
        _lastSuccessfulBaseUrl = baseUrl;
        return decodedResponse;
      } on ApiException {
        rethrow;
      } on TimeoutException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    throw ApiException(
      message:
          'Không thể kết nối API. Đã thử: ${_baseUrls.join(', ')}. '
          'Kiểm tra API_BASE_URL hoặc server.',
      cause: lastError,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decodedBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: (decodedBody['message'] ?? 'Request failed') as String,
      );
    }

    return decodedBody;
  }

  static List<String> _buildBaseUrls(String? baseUrl) {
    return {
      if (baseUrl != null && baseUrl.isNotEmpty) baseUrl,
      ...AppConfig.fallbackBaseUrls,
    }.toList();
  }
}

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}
