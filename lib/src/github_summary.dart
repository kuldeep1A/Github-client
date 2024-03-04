import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GithubSummary extends StatefulWidget {
  final GitHub gitHub;
  const GithubSummary({required this.gitHub, super.key});

  @override
  State<GithubSummary> createState() => _GithubSummaryState();
}

class _GithubSummaryState extends State<GithubSummary> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Octicons.repo), label: Text('Repositories')),
            NavigationRailDestination(
                icon: Icon(Octicons.issue_opened),
                label: Text('Assigned Issues')),
            NavigationRailDestination(
                icon: Icon(Octicons.git_pull_request),
                label: Text('Pull Requests'))
          ],
          elevation: 4,
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
            child: IndexedStack(index: _selectedIndex, children: [
          RepositoriesList(gitHub: widget.gitHub),
          AssignedIssuesList(gitHub: widget.gitHub),
        ]))
      ],
    );
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<RepositoriesList> createState() => _RepositoriesListState();
}

class _RepositoriesListState extends State<RepositoriesList> {
  @override
  initState() {
    super.initState();
    _repositories = widget.gitHub.repositories.listRepositories().toList();
  }

  late Future<List<Repository>> _repositories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Repository>>(future: _repositories.then(
      (repositories) {
        // Sort repositories by updatedAt in descending order.
        // Note: This assumes that updatedAt is not null for all items. If it can be null,
        // you might want to handle that case explicitly to avoid runtime errors.
        repositories.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
        return repositories;
      },
    ), builder: (context, snapshot) {
      if (snapshot.hasError) {
        throw Center(child: Text('${snapshot.error}'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      var repositories = snapshot.data;
      return ListView.builder(
        primary: false,
        itemBuilder: (context, index) {
          var repository = repositories[index];

          return ListTile(
            title: Text(
                '${repository.owner?.login ?? ''} /${repository.name} - ${repository.language}'),
            subtitle: Text(repository.description),
            onTap: () => _launchUrl(this, repository.htmlUrl),
          );
        },
        itemCount: repositories!.length,
      );
    });
  }
}

class AssignedIssuesList extends StatefulWidget {
  const AssignedIssuesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<AssignedIssuesList> createState() => _AssignedIssuesListState();
}

class _AssignedIssuesListState extends State<AssignedIssuesList> {
  @override
  void initState() {
    super.initState();
    _assignedIssues = widget.gitHub.issues.listByUser().toList();
  }

  late Future<List<Issue>> _assignedIssues;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Issue>>(
        future: _assignedIssues,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw Center(child: Text('erorosdfl: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var assignedData = snapshot.data;
          return ListView.builder(
              itemBuilder: (context, index) {
                var assignedIssue = assignedData[index];
                return ListTile(
                  title: Text(assignedIssue.title),
                  subtitle: Text('${_nameWithOwer(assignedIssue)} '
                      'Issue #${assignedIssue.number}'
                      'opend by ${assignedIssue.user?.login ?? ''}'),
                  onTap: () => _launchUrl(this, assignedIssue.htmlUrl),
                );
              },
              itemCount: assignedData!.length);
        });
  }

  String _nameWithOwer(Issue assignedIssue) {
    final endIndex = assignedIssue.url.lastIndexOf('/issues/');
    return assignedIssue.url.substring(29, endIndex);
  }
}

Future<void> _launchUrl(State state, String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    if (state.mounted) {
      return showDialog(
          context: state.context,
          builder: (context) => AlertDialog(
                title: const Text('Navigation error'),
                content: Text('Could not launch $url'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'))
                ],
              ));
    }
  }
}
