import 'package:flutter/material.dart';
import 'src/github_login.dart';
import 'credentials/github_oauth_credentials.dart';

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
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: const Color.fromARGB(255, 231, 229, 234),
              elevation: 4,
            ),
            body: const Center(
                child: Text(
              'You are logged in to GitHub!',
            )),
          );
        });
  }
}
