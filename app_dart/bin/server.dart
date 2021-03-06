// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';

import 'package:cocoon_service/cocoon_service.dart';

/// For local development, you might want to set this to true.
const String _kCocoonUseInMemoryCache = 'COCOON_USE_IN_MEMORY_CACHE';

Future<void> main() async {
  await withAppEngineServices(() async {
    final bool inMemoryCache = Platform.environment[_kCocoonUseInMemoryCache] == 'true';
    final CacheService cache = CacheService(inMemory: inMemoryCache);

    final Config config = Config(dbService, cache);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final AuthenticationProvider swarmingAuthProvider = SwarmingAuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );
    final ServiceAccountInfo serviceAccountInfo = await config.deviceLabServiceAccount;

    /// LUCI service class to communicate with buildBucket service.
    final LuciBuildService luciBuildService = LuciBuildService(
      config,
      buildBucketClient,
      serviceAccountInfo,
    );

    /// Github status service to update the state of the build
    /// in the Github UI.
    final GithubStatusService githubStatusService = GithubStatusService(
      config,
      luciBuildService,
    );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final GithubChecksService githubChecksService = GithubChecksService(
      config,
    );

    final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
      '/api/append-log': AppendLog(config, authProvider),
      '/api/authorize-agent': AuthorizeAgent(config, authProvider),
      '/api/check-waiting-pull-requests': CheckForWaitingPullRequests(config, authProvider),
      '/api/create-agent': CreateAgent(config, authProvider),
      '/api/flush-cache': FlushCache(
        config,
        authProvider,
        cache: cache,
      ),
      '/api/get-authentication-status': GetAuthenticationStatus(config, authProvider),
      '/api/get-log': GetLog(config, authProvider),
      '/api/github-webhook-pullrequest': GithubWebhook(
        config,
        buildBucketClient: buildBucketClient,
        luciBuildService: luciBuildService,
        githubChecksService: githubChecksService,
      ),
      '/api/luci-status-handler': LuciStatusHandler(
        config,
        buildBucketClient,
        luciBuildService,
        githubStatusService,
        githubChecksService,
      ),
      '/api/push-build-status-to-github': PushBuildStatusToGithub(config, authProvider),
      '/api/push-gold-status-to-github': PushGoldStatusToGithub(config, authProvider),
      '/api/push-engine-build-status-to-github': PushEngineStatusToGithub(config, authProvider, luciBuildService),
      '/api/refresh-chromebot-status': RefreshChromebotStatus(config, authProvider, luciBuildService),
      '/api/refresh-github-commits': RefreshGithubCommits(config, authProvider),
      '/api/reserve-task': ReserveTask(config, authProvider),
      '/api/reset-devicelab-task': ResetDevicelabTask(
        config,
        authProvider,
      ),
      '/api/reset-prod-task': ResetProdTask(
        config,
        authProvider,
        luciBuildService,
      ),
      '/api/reset-try-task': ResetTryTask(
        config,
        authProvider,
        luciBuildService,
      ),
      '/api/update-agent-health': UpdateAgentHealth(config, authProvider),
      '/api/update-agent-health-history': UpdateAgentHealthHistory(config, authProvider),
      '/api/update-task-status': UpdateTaskStatus(config, swarmingAuthProvider),
      '/api/vacuum-clean': VacuumClean(config, authProvider),
      '/api/public/build-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBuildStatus(config),
        ttl: const Duration(seconds: 15),
      ),
      '/api/public/get-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetStatus(config),
      ),
      '/api/public/get-branches': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBranches(config),
        ttl: const Duration(minutes: 15),
      ),
      '/api/public/github-rate-limit-status': CacheRequestHandler<Body>(
        config: config,
        cache: cache,
        ttl: const Duration(minutes: 1),
        delegate: GithubRateLimitStatus(config),
      ),
    };

    return await runAppEngine((HttpRequest request) async {
      final RequestHandler<dynamic> handler = handlers[request.uri.path];
      if (handler != null) {
        await handler.service(request);
      } else {
        /// Requests with query parameters and anchors need to be trimmed to get the file path.
        // TODO(chillers): Use toFilePath(), https://github.com/dart-lang/sdk/issues/39373
        final int queryIndex = request.uri.path.contains('?') ? request.uri.path.indexOf('?') : request.uri.path.length;
        final int anchorIndex =
            request.uri.path.contains('#') ? request.uri.path.indexOf('#') : request.uri.path.length;

        /// Trim to the first instance of an anchor or query.
        final int trimIndex = min(queryIndex, anchorIndex);
        final String filePath = request.uri.path.substring(0, trimIndex);

        const Map<String, String> redirects = <String, String>{
          '/build.html': '/#/build',
          '/repository': '/repository/index.html',
          '/repository/': '/repository/index.html',
          '/repository.html': '/repository/index.html',
        };
        if (redirects.containsKey(filePath)) {
          request.response.statusCode = HttpStatus.permanentRedirect;
          return await request.response.redirect(Uri.parse(redirects[filePath]));
        }

        await StaticFileHandler(filePath, config: config).service(request);
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      final String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at http://$host:$port/');
    });
  });
}
