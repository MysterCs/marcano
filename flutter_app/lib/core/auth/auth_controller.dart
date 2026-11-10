import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/auth_session.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/api_client.dart';
import '../../data/services/session_storage.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required SessionStorage sessionStorage,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _sessionStorage = sessionStorage,
        _apiClient = apiClient {
    _apiClient.onUnauthorized = _handleUnauthorized;
  }

  final AuthRepository _authRepository;
  final SessionStorage _sessionStorage;
  final ApiClient _apiClient;

  AuthStatus _status = AuthStatus.initializing;
  AuthUser? _user;
  String? _errorMessage;
  bool _isBusy = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;

  Future<void> restore() async {
    _status = AuthStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _sessionStorage.readToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
      } else {
        _apiClient.authToken = token;
        _user = await _authRepository.me();
        _status = AuthStatus.authenticated;
      }
    } catch (error) {
      _apiClient.authToken = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      if (error is ApiException && error.statusCode == 401) {
        await _sessionStorage.clearToken();
      } else {
        _errorMessage = _messageFor(error);
      }
    }
    notifyListeners();
  }

  Future<bool> login({required String cedula, required String password}) =>
      _authenticate(
        () => _authRepository.login(cedula: cedula, password: password),
      );

  Future<bool> register({
    required String fullName,
    required String cedula,
    required String password,
  }) =>
      _authenticate(() async {
        await _authRepository.register(
          fullName: fullName,
          cedula: cedula,
          password: password,
        );
        return _authRepository.login(cedula: cedula, password: password);
      });

  Future<bool> _authenticate(
    Future<AuthSession> Function() authenticate,
  ) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authenticate();
      await _sessionStorage.saveToken(session.accessToken);
      _apiClient.authToken = session.accessToken;
      _user = session.user;
      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.authenticated) unawaited(logout());
  }

  Future<void> logout() async {
    await _sessionStorage.clearToken();
    _apiClient.authToken = null;
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiClient.onUnauthorized = null;
    super.dispose();
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'No se pudo conectar con la API. Intentalo de nuevo.';
  }
}
