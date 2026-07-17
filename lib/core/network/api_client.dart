import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around xpenzes-svc. Every call attaches the current
/// Supabase session's access token as a bearer token — the API resolves
/// the caller from that token, never from a client-supplied user id.
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              contentType: 'application/json',
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token =
              Supabase.instance.client.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  String _path(String path) => path.startsWith('/') ? path : '/$path';

  Never _throwApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      throw ApiException(0, e.message ?? 'Network error');
    }
    final data = response.data;
    throw ApiException(
      response.statusCode ?? 0,
      data is String ? data : (data?.toString() ?? ''),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(_path(path), queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    try {
      final response = await _dio.post(_path(path), data: body);
      return response.data;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    try {
      final response = await _dio.patch(_path(path), data: body);
      return response.data;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<dynamic> put(String path, {Object? body}) async {
    try {
      final response = await _dio.put(_path(path), data: body);
      return response.data;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(_path(path));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }
}

final apiClient = ApiClient();
