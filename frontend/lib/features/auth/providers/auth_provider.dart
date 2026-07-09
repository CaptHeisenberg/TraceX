import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/secure_storage.dart';
import '../../../models/user.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient, secureStorage);
});

class AuthNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  User? _currentUser = User(
    id: 'supabase-operator-1',
    name: 'AOI Supervisor',
    email: 'operator@tracex.com',
    createdAt: DateTime.now(),
  );
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = true;

  AuthNotifier(this._apiClient, this._secureStorage) {
    // tryAutoLogin();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _secureStorage.getToken();
      if (token != null) {
        final response = await _apiClient.get('/auth/profile');
        if (response.statusCode == 200) {
          _currentUser = User.fromJson(response.data as Map<String, dynamic>);
        } else {
          await _secureStorage.deleteToken();
        }
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      // Token might be expired or host unreachable, delete token only if it's an auth error
      if (e is DioException && e.response?.statusCode == 401) {
        await _secureStorage.deleteToken();
      }
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['access_token'] as String;
        await _secureStorage.saveToken(token);
        
        // Fetch profile
        final profileResponse = await _apiClient.get('/auth/profile');
        if (profileResponse.statusCode == 200) {
          _currentUser = User.fromJson(profileResponse.data as Map<String, dynamic>);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _error = 'Login failed. Please try again.';
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        // Automatically login after signup
        return await login(email, password);
      }
      _error = 'Signup failed.';
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/forgot-password', data: {
        'email': email,
      });
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final detail = e.response?.data['detail'];
        if (detail != null) {
          return detail.toString();
        }
        return 'Server error (${e.response?.statusCode})';
      }
      return 'Network error. Please check your connection.';
    }
    return e.toString();
  }
}
