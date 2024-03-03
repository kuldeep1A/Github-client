import 'package:flutter/material.dart';
import 'src/github_login.dart';
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
        return FutureBuilder<CurrentUser>(
            future: viewerDetials(httpClient.credentials.accessToken),
            builder: (context, snapshot) {
              return Scaffold(
                appBar: AppBar(title: Center(child: Text(title)), elevation: 4),
                body: Center(
                    child: Text(snapshot.hasData
                        ? 'Hello ${snapshot.data!.login}!'
                        : 'Retrieving viewer login details...')),
              );
            });
      },
    );
  }
}

Future<CurrentUser> viewerDetials(String accessToken) async {
  final github = GitHub(auth: Authentication.withToken(accessToken));
  return github.users.getCurrentUser();
}
