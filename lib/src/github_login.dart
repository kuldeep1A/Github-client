import 'dart:io';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client, String userName);

final _authorizationEndpoint =
    Uri.parse('https://github.com/login/oauth/authorize');
final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget(
      {super.key,
      required this.githubClientId,
      required this.githubClientSecret,
      required this.githubScopes,
      required this.builder});

  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;
  final AuthenticatedBuilder builder;

  @override
  State<GithubLoginWidget> createState() => _GithubLoginState();
}

class _GithubLoginState extends State<GithubLoginWidget> {
  HttpServer? _redirectServer;
  oauth2.Client? _client;
  String? _username;

  @override
  Widget build(BuildContext context) {
    final client = _client;
    final userName = _username;
    if (client != null) {
      return widget.builder(context, client, userName!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Github Login'),
        backgroundColor: const Color.fromARGB(255, 231, 229, 234),
        elevation: 4,
      ),
      body: Center(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20.0),
              ),
              child: const Text('Login to Github'),
              onPressed: () async {
                await _redirectServer?.close();
                _redirectServer = await HttpServer.bind('localhost', 0);
                var authenticatedHttpClient = await _getOAuth2Client(Uri.parse(
                    'http://localhost:${_redirectServer!.port}/auth'));
                var username = await _getUsername(authenticatedHttpClient);
                setState(() {
                  _client = authenticatedHttpClient;
                  _username = username;
                });
              })),
    );
  }

  Future<String?> _getUsername(oauth2.Client client) async {
    try {
      final github = GitHub(client: client);
      final currentUser = await github.users.getCurrentUser();
      return currentUser.login;
    } catch (e) {
      return null;
    }
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException(
          'githubClientId and githubClientSecret must be not empty.'
          'See `lib/credential/..` for more detail.');
    }
    var grant = oauth2.AuthorizationCodeGrant(
        widget.githubClientId, _authorizationEndpoint, _tokenEndpoint,
        secret: widget.githubClientSecret,
        httpClient: _JsonAcceptingHttpClient());

    var authorizationUrl =
        grant.getAuthorizationUrl(redirectUrl, scopes: widget.githubScopes);
    _redirect(authorizationUrl);
    var responseQueryParameters = await _listenParameters();
    var client = grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    } else {
      throw GithubLoginException('Could not lunch $authorizationUrl');
    }
  }

  Future<Map<String, String>> _listenParameters() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln(
        '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\tAuthenticated! You can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}
