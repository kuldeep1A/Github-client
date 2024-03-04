import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GithubSummary extends StatefulWidget {
  final GitHub gitHub;
  final String username;
  const GithubSummary(
      {required this.gitHub, required this.username, super.key});
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
          PullRequestList(gitHub: widget.gitHub, username: widget.username),
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
              '${repository.owner?.login ?? ''}/${repository.name} - ${repository.language}',
              style: const TextStyle(fontSize: 18),
            ),
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
              primary: false,
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

class PullRequestList extends StatefulWidget {
  const PullRequestList(
      {required this.gitHub, required this.username, super.key});
  final GitHub gitHub;
  final String username;
  @override
  State<PullRequestList> createState() => _PullRequestListState();
}

class _PullRequestListState extends State<PullRequestList> {
  @override
  void initState() {
    super.initState();
    _pullRequests = Future.value(<PullRequest>[]);
  }

  late Future<List<PullRequest>> _pullRequests;

  void _initializePullRequests() {
    if (reposName.isNotEmpty) {
      _pullRequests = widget.gitHub.pullRequests
          .list(RepositorySlug(widget.username, reposName))
          .toList();
    }
  }

  TextEditingController controller = TextEditingController();
  String reposName = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 300.0,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter repo name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      reposName = value;
                    });
                    _initializePullRequests();
                  },
                ),
              )),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<List<PullRequest>>(
              future: _pullRequests,
              builder: (context, snapshot) {
                if (reposName == '') {
                  return const Center(
                      child: Text('Please Enter perfect repos name'));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var pullRequests = snapshot.data;
                if (pullRequests!.isEmpty) {
                  return const Text(
                      'This repository does not have any pull request!');
                } else {
                  return ListView.builder(
                    primary: false,
                    itemBuilder: (context, index) {
                      var pullRequest = pullRequests[index];
                      return ListTile(
                        title: Text(pullRequest.title ?? ''),
                        subtitle:
                            Text('${widget.gitHub.auth.username}/$reposName'
                                'PR #${pullRequest.number}'
                                'opened by ${pullRequest.user?.login ?? ''}'
                                '(${pullRequest.state?.toLowerCase() ?? ''} )'),
                        onTap: () => _launchUrl(this, '${pullRequest.htmlUrl}'),
                      );
                    },
                    itemCount: pullRequests.length,
                  );
                }
              }),
        ))
      ],
    );
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
