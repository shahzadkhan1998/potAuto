import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linkedin_login/linkedin_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/post.dart';
import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class LinkedInService {
  static const String _baseUrl = 'https://api.linkedin.com/v2';
  late SharedPreferences _prefs;

  // Use the provided access token directly
  String? _accessToken =
      'AQVoLxZe0N8lSAze_NsnUIxD4B-GETPtaXacwv91qaX2DV7Px6e10JAFAgNb0skn3m8cIMCr15a4K1X5idFJn5VojJVcdGeMlfAL2m2lKD7bWr0kGENJ1kJryuH8JwOwB6SbiHnOgTMQdON4uR4Y3PIk88TMO65TlckMEpNWDfgMHXbqiwhRnSBwbtdb4KlpItKZgl5fTZzCluiUwioXzj7lRE_khhf4zzAtFZqobxW6dJMW1IkOR-NjQrKHbW7CsXWdB01fatFBe0X83A30REdNk2oAxUSpZtqMmtjajEazPFb-608onAM1j-qvkfFLeI4xk6UY6d-IQtppA3p8hLPUFMsYRQ';
  String? _clientId;
  String? _clientSecret;
  UserObject? _user;

  bool _isLoggedOut = false;

  // Initialize SharedPreferences in the constructor
  LinkedInService() {
    _initPrefs();
    _clientId = dotenv.env['LINKEDIN_CLIENT_ID'];
    _clientSecret = dotenv.env['LINKEDIN_CLIENT_SECRET'];
    _setInitialToken();

    if (_clientId == null || _clientSecret == null) {
      debugPrint(
        'WARNING: LinkedIn credentials not found in environment variables',
      );
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = _prefs.getString('linkedin_token');
  }

  Future<void> _setInitialToken() async {
    // Set the initial access token if not already set
    const initialToken =
        'AQW2vpIHUMCRbrGU25iNqzuxLliNeZ_oCU4eu_raiUkbXMTFxTvZXcI-IJR7vmzyMV71I7NwW0CMigcPF_sDGAiNTp-ax6g_y0mzByimO1VpZZWFE-PMvMA21R7xpUG-A3HsCdTtaIR9caUFu7Pxn9s1nHkf7pyubHRAznnyCPz8nsix7oRXSn3vmIxuS-6-dQs_mhB5GXbxByCk4bMdDYb87vKFGFIyL4BxFrs2RWGxGfD775gARudRP85ogm9tDHxxNZYutO7k6ltozg2o3F0Z8HSoHOuVzr08Ep6sOoK9iOSYNbkPs5ZPv7977hqS1Dezzu8zMGhS5cA6slF97WAW5A2BMA';
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('linkedin_token') == null) {
      await _prefs.setString('linkedin_token', initialToken);
      _accessToken = initialToken;
    }
  }

  // LinkedIn API credentials
  static const String redirectUrl =
      'https://www.linkedin.com/developers/tools/oauth/redirect';

  Future<bool> authenticate() async {
    try {
      if (_clientId == null || _clientSecret == null) {
        throw Exception('LinkedIn credentials not configured');
      }

      debugPrint('Starting LinkedIn authentication');
      bool authResult = false;

      // Check if we already have a valid token
      if (_accessToken != null) {
        debugPrint('Using existing access token');
        return true;
      }

      await Navigator.push(
        NavigationService.navigatorKey.currentContext!,
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) => LinkedInUserWidget(
                redirectUrl: redirectUrl,
                clientId: _clientId!,
                clientSecret: _clientSecret!,
                projection: [
                  ProjectionParameters.id,
                  ProjectionParameters.localizedFirstName,
                  ProjectionParameters.localizedLastName,
                  ProjectionParameters.profilePicture,
                ],
                destroySession: _isLoggedOut,
                onError: (UserFailedAction e) {
                  debugPrint('LinkedIn authentication error: ${e.toString()}');
                  throw Exception('Authentication failed: $e');
                },
                onGetUserProfile: (UserSucceededAction linkedInUser) async {
                  _accessToken = linkedInUser.user.token.accessToken;
                  await _prefs.setString('linkedin_token', _accessToken!);
                },
                scope: const [LiteProfileScope(), EmailAddressScope()],
              ),
          fullscreenDialog: true,
        ),
      );

      if (!authResult && _accessToken == null) {
        throw Exception('No authentication token received');
      }

      debugPrint('Successfully authenticated with LinkedIn');
      return true;
    } catch (e, stack) {
      debugPrint('Authentication error: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to authenticate with LinkedIn: $e');
    }
  }

  Future<void> sharePost(Post post) async {
    try {
      debugPrint('Attempting to share post on LinkedIn');

      final response = await http.post(
        Uri.parse('$_baseUrl/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'X-Restli-Protocol-Version': '2.0.0',
        },
        body: jsonEncode({
          'author': 'urn:li:person:${await _getUserId()}',
          'lifecycleState': 'PUBLISHED',
          'specificContent': {
            'com.linkedin.ugc.ShareContent': {
              'shareCommentary': {
                'text':
                    post.content +
                    (post.hashtags?.isNotEmpty == true
                        ? '\n\n${post.hashtags!.join(' ')}'
                        : ''),
              },
              'shareMediaCategory': 'NONE',
            },
          },
          'visibility': {'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC'},
        }),
      );

      if (response.statusCode != 201) {
        debugPrint('LinkedIn API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception(
          'Failed to share post: ${_parseErrorMessage(response.body)}',
        );
      }

      debugPrint('Successfully shared post on LinkedIn');
    } catch (e, stack) {
      debugPrint('Error sharing post: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to share post: $e');
    }
  }

  Future<void> shareArticle(Post article) async {
    if (_accessToken == null) {
      final storedToken = _prefs.getString('linkedin_token');
      if (storedToken == null) {
        throw Exception('Not authenticated');
      }
      _accessToken = storedToken;
    }

    try {
      debugPrint('Attempting to publish article on LinkedIn');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/articles'),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
              'X-Restli-Protocol-Version': '2.0.0',
            },
            body: jsonEncode({
              'author': 'urn:li:person:${await _getUserId()}',
              'lifecycleState': 'PUBLISHED',
              'title': article.title,
              'content': article.content,
              'tags': article.hashtags ?? [],
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('LinkedIn API request timed out');
              throw Exception('Request timed out. Please try again.');
            },
          );

      if (response.statusCode != 201) {
        debugPrint('LinkedIn API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception(
          'Failed to publish article: ${_parseErrorMessage(response.body)}',
        );
      }

      debugPrint('Successfully published article on LinkedIn');
    } catch (e, stack) {
      debugPrint('Error publishing article: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to publish article: $e');
    }
  }

  Future<String> _getUserId() async {
    if (_accessToken == null) {
      throw Exception('Access token is null. Please authenticate first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/userinfo'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) {
        debugPrint('LinkedIn API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to get user ID: ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data['sub'] == null) {
        throw Exception('User ID (sub) is missing in the API response.');
      }

      return data['sub'];
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['message'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'Failed to parse error message';
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out from LinkedIn');
    _accessToken = null;
    _user = null;
    _isLoggedOut = true;
    await _prefs.remove('linkedin_token');
  }

  // Get current user information
  UserObject? get currentUser => _user;
}

class UserObject {
  UserObject({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileImageUrl,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profileImageUrl;
}

class LiteProfileScope extends Scope {
  const LiteProfileScope() : super('r_liteprofile');
}

class EmailAddressScope extends Scope {
  const EmailAddressScope() : super('r_emailaddress');
}

// Usage example
List<Scope> scope = const [LiteProfileScope(), EmailAddressScope()];
