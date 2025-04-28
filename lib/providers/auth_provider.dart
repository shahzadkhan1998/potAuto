import 'package:flutter/foundation.dart';
import '../services/linkedin_service.dart';

class AuthProvider with ChangeNotifier {
  final LinkedInService _linkedInService = LinkedInService();

  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String? _error;
  String? _currentOperation;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  String? get error => _error;
  String? get currentOperation => _currentOperation;

  Future<void> authenticate() async {
    try {
      _resetState();
      _setAuthenticating(true);
      _updateOperation('Initializing LinkedIn authentication...');

      debugPrint('Starting LinkedIn authentication process');
      _isAuthenticated = await _linkedInService.authenticate();

      if (_isAuthenticated) {
        debugPrint('Successfully authenticated with LinkedIn');
        _updateOperation('Authentication successful');
      } else {
        debugPrint('Authentication failed: No token received');
        throw Exception('Failed to authenticate with LinkedIn');
      }
    } catch (e, stack) {
      debugPrint('Authentication error: $e');
      debugPrint('Stack trace: $stack');
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _setAuthenticating(false);
    }
    notifyListeners();
  }

  void logout() {
    debugPrint('Starting logout process');
    try {
      _linkedInService.logout();
      _isAuthenticated = false;
      _resetState();
      debugPrint('Successfully logged out');
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Even if logout fails, we want to clear the local state
      _isAuthenticated = false;
      _error = 'Failed to logout properly: $e';
    }
    notifyListeners();
  }

  void _resetState() {
    _error = null;
    _currentOperation = null;
    notifyListeners();
  }

  void _updateOperation(String operation) {
    _currentOperation = operation;
    notifyListeners();
    debugPrint('Operation: $operation');
  }

  void _setAuthenticating(bool value) {
    _isAuthenticating = value;
    if (!value) {
      _currentOperation = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('Disposing AuthProvider');
    super.dispose();
  }
}
