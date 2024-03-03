import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

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
  State<GithubLoginWidget> createState() => _GithubLoginWidget();
}

class _GithubLoginWidget extends State<GithubLoginWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Github Login')),
      body: Center(
          child: ElevatedButton(
              child: const Text('Login to Github'), onPressed: () => {})),
    );
  }
}
