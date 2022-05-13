// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'auto_submit_query_result.g.dart';

/// The classes in this file are used to serialize/deserialize graphql results.
/// Using classes rather than complex maps improves the readability of the code
/// and makes possible to define an extensible interface for the validations.

@JsonSerializable()
class Author {
  Author({
    this.login,
  });
  final String? login;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}

@JsonSerializable()
class ReviewNode {
  ReviewNode({
    this.author,
    this.authorAssociation,
    this.state,
  });
  final Author? author;
  @JsonKey(name: 'authorAssociation')
  final String? authorAssociation;
  final String? state;

  factory ReviewNode.fromJson(Map<String, dynamic> json) => _$ReviewNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewNodeToJson(this);
}

@JsonSerializable()
class Reviews {
  Reviews({this.nodes});

  List<ReviewNode>? nodes;

  factory Reviews.fromJson(Map<String, dynamic> json) => _$ReviewsFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewsToJson(this);
}

@JsonSerializable()
class CommitNode {
  CommitNode({this.commit});

  Commit? commit;

  factory CommitNode.fromJson(Map<String, dynamic> json) => _$CommitNodeFromJson(json);

  Map<String, dynamic> toJson() => _$CommitNodeToJson(this);
}

@JsonSerializable()
class Commits {
  Commits({this.nodes});

  List<CommitNode>? nodes;

  factory Commits.fromJson(Map<String, dynamic> json) => _$CommitsFromJson(json);

  Map<String, dynamic> toJson() => _$CommitsToJson(this);
}

@JsonSerializable()
class ContextNode {
  ContextNode({
    this.context,
    this.state,
    this.targetUrl,
  });

  String? context;
  String? state;
  @JsonKey(name: 'targetUrl')
  String? targetUrl;

  factory ContextNode.fromJson(Map<String, dynamic> json) => _$ContextNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ContextNodeToJson(this);
}

@JsonSerializable()
class Status {
  Status({this.contexts});

  List<ContextNode>? contexts;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
class Commit {
  Commit({
    this.abbreviatedOid,
    this.oid,
    this.committedDate,
    this.pushedDate,
    this.status,
  });
  @JsonKey(name: 'abbreviatedOid')
  final String? abbreviatedOid;
  final String? oid;
  @JsonKey(name: 'committedDate')
  final DateTime? committedDate;
  @JsonKey(name: 'pushedDate')
  final DateTime? pushedDate;
  final Status? status;

  factory Commit.fromJson(Map<String, dynamic> json) => _$CommitFromJson(json);

  Map<String, dynamic> toJson() => _$CommitToJson(this);
}

@JsonSerializable()
class PullRequest {
  PullRequest({
    this.author,
    this.authorAssociation,
    this.id,
    this.title,
    this.reviews,
    this.commits,
  });
  final Author? author;
  @JsonKey(name: 'authorAssociation')
  final String? authorAssociation;
  final String? id;
  final String? title;
  final Reviews? reviews;
  final Commits? commits;

  factory PullRequest.fromJson(Map<String, dynamic> json) => _$PullRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestToJson(this);
}

@JsonSerializable()
class Repository {
  Repository({
    this.pullRequest,
  });

  @JsonKey(name: 'pullRequest')
  PullRequest? pullRequest;

  factory Repository.fromJson(Map<String, dynamic> json) => _$RepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryToJson(this);
}

@JsonSerializable()
class QueryResult {
  QueryResult({
    this.repository,
  });

  Repository? repository;

  factory QueryResult.fromJson(Map<String, dynamic> json) => _$QueryResultFromJson(json);

  Map<String, dynamic> toJson() => _$QueryResultToJson(this);
}