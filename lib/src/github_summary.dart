import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

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
  String _repositoryName = '';

  void _navigateToCommits(String repo) {
    setState(() {
      _selectedIndex = 3;
      _repositoryName = repo;
    });
  }

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
                label: Text('Pull Requests')),
            NavigationRailDestination(
                icon: Icon(Octicons.git_commit), label: Text('Commits'))
          ],
          elevation: 4,
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
            child: IndexedStack(index: _selectedIndex, children: [
          RepositoriesList(
              gitHub: widget.gitHub, onNavigateToCommits: _navigateToCommits),
          AssignedIssuesList(gitHub: widget.gitHub),
          PullRequestList(gitHub: widget.gitHub, username: widget.username),
          CommitsList(
              gitHub: widget.gitHub,
              username: widget.username,
              repositoryName: _repositoryName)
        ]))
      ],
    );
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList(
      {required this.gitHub, required this.onNavigateToCommits, super.key});
  final GitHub gitHub;
  final Function(String) onNavigateToCommits;

  @override
  State<RepositoriesList> createState() => _RepositoriesListState();
}

class _RepositoriesListState extends State<RepositoriesList> {
  late Future<List<Repository>> _allRepositories;
  late Future<List<Repository>> _filteredRepositories;

  @override
  initState() {
    super.initState();
    _allRepositories = widget.gitHub.repositories.listRepositories().toList();
    _filteredRepositories = _allRepositories;
  }

  TextEditingController controller = TextEditingController();
  String reposName = '';

  Future<List<Repository>> _filterRepositories(String reponame) async {
    var allRepositories = await _allRepositories;
    if (reposName.isEmpty) {
      return allRepositories;
    } else {
      return allRepositories
          .where((repo) => repo.name.toLowerCase().contains(reponame))
          .toList();
    }
  }

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
                    labelText: 'Enter repository name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      reposName = value;
                      _filteredRepositories =
                          _filterRepositories(reposName.toLowerCase());
                    });
                  },
                ),
              )),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: FutureBuilder<List<Repository>>(
              future: _filteredRepositories.then(
            (repositories) {
              // Sort repositories by updatedAt in descending order.
              // Note: This assumes that updatedAt is not null for all items. If it can be null,
              // you might want to handle that case explicitly to avoid runtime errors.
              repositories.sort((a, b) => b.pushedAt!.compareTo(a.pushedAt!));
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
            if (repositories!.isEmpty) {
              return const Center(
                  child: Text('Your Search Repo does not exist!'));
            } else {
              return ListView.builder(
                primary: false,
                itemBuilder: (context, index) {
                  var repository = repositories[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _launchUrl(this, repository.htmlUrl),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${repository.owner?.login ?? ''}/${repository.name} - ${repository.isPrivate ? 'Private' : 'Public'}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${repository.language} ${repository.description}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () =>
                              widget.onNavigateToCommits(repository.name),
                          icon: const Icon(Octicons.git_commit)),
                      const SizedBox(width: 20.0),
                    ],
                  );
                },
                itemCount: repositories.length,
              );
            }
          }),
        )
      ],
    );
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
            throw Center(child: Text('Error: ${snapshot.error}'));
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
                    labelText: 'Enter repository name',
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
                        subtitle: Text('${widget.username}/$reposName'
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

class CommitsList extends StatefulWidget {
  const CommitsList(
      {required this.gitHub,
      required this.username,
      required this.repositoryName,
      super.key});
  final GitHub gitHub;
  final String username;
  final String repositoryName;

  @override
  State<CommitsList> createState() => _CommitsListState();
}

class _CommitsListState extends State<CommitsList> {
  TextEditingController controller = TextEditingController();
  late String reposName;
  late Future<List<RepositoryCommit>> _commitsList;

  @override
  void initState() {
    super.initState();
    reposName = '';
    _commitsList = Future.value(<RepositoryCommit>[]);
    _initializeCommitsList();
  }

  @override
  void didUpdateWidget(covariant CommitsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repositoryName != oldWidget.repositoryName) {
      reposName = widget.repositoryName;
      controller.text = widget.repositoryName;
      _initializeCommitsList();
    }
  }

  void _initializeCommitsList() {
    if (reposName.isNotEmpty) {
      _commitsList = widget.gitHub.repositories
          .listCommits(RepositorySlug(widget.username, reposName))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 300.0,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter repository name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      reposName = value;
                    });
                    _initializeCommitsList();
                  },
                ),
              ),
              const SizedBox(
                width: 10.0,
              ),
              FutureBuilder(
                future: _commitsList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Number of commits: 0');
                  } else {
                    return Text(
                        'Number of commits: ${snapshot.data?.length ?? '0'} ');
                  }
                },
              )
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<List<RepositoryCommit>>(
              future: _commitsList,
              builder: (context, snapshot) {
                var commitsListData = snapshot.data;
                if (reposName == '') {
                  return const Center(
                      child: Text('Please Enter perfect repos name'));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (commitsListData!.isEmpty) {
                  return const Text(
                      'This repository does not have any commit!');
                } else {
                  return ListView.builder(
                    primary: false,
                    itemBuilder: (context, index) {
                      var commit = commitsListData[index];
                      var commitMessage =
                          commit.commit?.message?.split('\n')[0] ??
                              'No message';
                      var committerName = commit.committer?.login ?? 'Unknown';
                      var commitDate =
                          commit.commit?.committer?.date ?? DateTime.now();
                      var commitUrl = commit.htmlUrl ?? '';
                      return ListTile(
                        title: Text('@$commitMessage'),
                        subtitle: Text(
                            '$committerName committed ${_formattedDate(commitDate)}'),
                        onTap: () => _launchUrl(this, commitUrl),
                      );
                    },
                    itemCount: commitsListData.length,
                  );
                }
              }),
        ))
      ],
    );
  }

  String _formattedDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
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
