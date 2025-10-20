import 'package:dio/dio.dart';

import 'api_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthService {
  final ApiClient _api = ApiClient();

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _api.dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final token = (data['access_token'] ?? '') as String;
      if (token.isEmpty) {
        throw ApiException('Missing access token', statusCode: res.statusCode);
      }
      await _api.setAuthToken(token);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/api/auth/logout');
    } catch (_) {
      // ignore logout errors
    }
    await _api.setAuthToken(null);
  }

  Future<Map<String, dynamic>> profile() async {
    try {
      final res = await _api.dio.get('/api/auth/profile');
      return (res.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Network error';
    if (status == 401) {
      message = 'Invalid credentials';
    } else if (status == 400) {
      if (data is Map && data['detail'] is String) {
        message = data['detail'] as String;
      } else {
        message = 'Bad request';
      }
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Check API_BASE_URL or start backend.';
    } else if (e.message != null && e.message!.isNotEmpty) {
      message = e.message!;
    }
    return ApiException(message, statusCode: status);
  }
}