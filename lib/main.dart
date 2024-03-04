import 'package:flutter/material.dart';
import 'src/github_login.dart';
import 'src/github_summary.dart';
import 'credentials/github_oauth_credentials.dart';
import 'package:github/github.dart';
import 'package:window_to_front/window_to_front.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Github Client'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
      githubClientId: githubClientId,
      githubClientSecret: githubClientSecret,
      githubScopes: githubScopes,
      builder: (context, httpClient) {
        WindowToFront.activate();
        return Scaffold(
            appBar: AppBar(title: Center(child: Text(title)), elevation: 4),
            body: GithubSummary(
                gitHub: _getGithub(httpClient.credentials.accessToken)));
      },
    );
  }
}

GitHub _getGithub(String accessToken) {
  return GitHub(auth: Authentication.withToken(accessToken));
}
