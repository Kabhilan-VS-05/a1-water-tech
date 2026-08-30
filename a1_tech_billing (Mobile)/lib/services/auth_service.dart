import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'logger_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late CognitoUserPool _userPool;
  CognitoUser? _currentUser;
  CognitoUserSession? _session;

  // Initialize Cognito
  Future<void> initialize() async {
    _userPool = CognitoUserPool(
      AppConfig.cognitoUserPoolId,
      AppConfig.cognitoClientId,
    );

    // Get current user
    final currentUser = await _userPool.getCurrentUser();
    if (currentUser != null) {
      _currentUser = currentUser;
      await _getCurrentSession();
    }
  }

  Future<void> _getCurrentSession() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      _session = await user.getSession();
      if (_session?.isValid() == true) {
        AppLogger.info('User is authenticated: ${user.username}', tag: 'Auth');
      }
    } catch (e) {
      AppLogger.debug('No active session: $e', tag: 'Auth');
      _session = null;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _session?.isValid() ?? false;

  String? get currentUser => _currentUser?.username;

  String? get idToken {
    return _session?.idToken.jwtToken;
  }

  String? get accessToken {
    return _session?.accessToken.jwtToken;
  }

  // Sign in with username and password
  Future<AuthResult> signIn(String username, String password) async {
    try {
      _currentUser = CognitoUser(username, _userPool);

      final authDetails = AuthenticationDetails(
        username: username,
        password: password,
      );

      _session = await _currentUser!.authenticateUser(authDetails);

      if (_session?.isValid() == true) {
        await _saveUserSession();

        AppLogger.info('Sign in successful for: $username', tag: 'Auth');
        return AuthResult.success;
      } else {
        return AuthResult.failed;
      }
    } on CognitoClientException catch (e) {
      AppLogger.error('Cognito error: ${e.message}', tag: 'Auth');
      if (e.code == 'NotAuthorizedException') {
        return AuthResult.invalidCredentials;
      } else if (e.code == 'UserNotConfirmedException') {
        return AuthResult.userNotConfirmed;
      }
      return AuthResult.failed;
    } catch (e) {
      AppLogger.error('Sign in error: $e', tag: 'Auth');
      return AuthResult.failed;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _currentUser?.signOut();
      _session = null;

      // Clear stored session
      await _clearUserSession();

      AppLogger.info('User signed out', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Sign out error: $e', tag: 'Auth');
    }
  }

  // Get authenticated HTTP headers for API calls
  Map<String, String> get authHeaders {
    final token = idToken;
    if (token != null) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // Make authenticated API call
  Future<http.Response> makeAuthenticatedRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final requestHeaders = <String, String>{...authHeaders, ...?headers};

    final uri = Uri.parse(url);

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: requestHeaders);
      case 'POST':
        return await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: requestHeaders);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // Store user session locally
  Future<void> _saveUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _currentUser?.username ?? '');
      await prefs.setString('id_token', idToken ?? '');
      await prefs.setString('access_token', accessToken ?? '');
      await prefs.setString(
        'refresh_token',
        _session?.refreshToken?.token ?? '',
      );
    } catch (e) {
      AppLogger.error('Error saving session: $e', tag: 'Auth');
    }
  }

  // Clear stored user session
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('id_token');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      AppLogger.error('Error clearing session: $e', tag: 'Auth');
    }
  }

  // Restore session from local storage
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final idToken = prefs.getString('id_token');
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

      if (username != null && idToken != null && accessToken != null) {
        _currentUser = CognitoUser(username, _userPool);

        // Create session from stored tokens
        _session = CognitoUserSession(
          CognitoIdToken(idToken),
          CognitoAccessToken(accessToken),
          refreshToken: refreshToken == null || refreshToken.isEmpty
              ? null
              : CognitoRefreshToken(refreshToken),
        );

        if (_session?.isValid() == true) {
          AppLogger.info('Session restored for: $username', tag: 'Auth');
        } else {
          await _refreshSession();
        }
      }
    } catch (e) {
      AppLogger.error('Error restoring session: $e', tag: 'Auth');
      await _clearUserSession();
    }
  }

  // Refresh session using refresh token
  Future<void> _refreshSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken != null && _currentUser != null) {
        final newSession = await _currentUser!.refreshSession(
          CognitoRefreshToken(refreshToken),
        );
        if (newSession?.isValid() == true) {
          _session = newSession;
          await _saveUserSession();
          AppLogger.info('Session refreshed successfully', tag: 'Auth');
        }
      }
    } catch (e) {
      AppLogger.error('Error refreshing session: $e', tag: 'Auth');
      await _clearUserSession();
    }
  }

  // Dispose
  void dispose() {
    _session = null;
  }
}

enum AuthResult {
  success,
  failed,
  invalidCredentials,
  userNotConfirmed,
  networkError,
}

extension AuthResultExtension on AuthResult {
  String get message {
    switch (this) {
      case AuthResult.success:
        return 'Sign in successful';
      case AuthResult.failed:
        return 'Sign in failed';
      case AuthResult.invalidCredentials:
        return 'Invalid username or password';
      case AuthResult.userNotConfirmed:
        return 'User account not confirmed';
      case AuthResult.networkError:
        return 'Network error. Please try again';
    }
  }
}
