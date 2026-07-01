import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/playable_media.dart';
import '../domain/schedule_sync_config.dart';
import 'media_cache_service.dart';
import 'schedule_local_data_source.dart';
import 'schedule_remote_data_source.dart';

class ScheduleRepository {
  ScheduleRepository({
    required ScheduleLocalDataSource localDataSource,
    required MediaCacheService mediaCacheService,
    required ScheduleRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _mediaCacheService = mediaCacheService,
       _remoteDataSource = remoteDataSource;

  final ScheduleLocalDataSource _localDataSource;
  final MediaCacheService _mediaCacheService;
  final ScheduleRemoteDataSource _remoteDataSource;

  Future<List<PlayableMedia>> getCurrentPlaylist({
    required String? apiToken,
  }) async {
    try {
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('Missing device API token');
      }

      final serverNow = await _remoteDataSource.getServerTime(
        apiToken: apiToken,
      );
      await _localDataSource.cacheServerClockOffset(
        serverNow.difference(DateTime.now()),
      );

      final playlist = await _remoteDataSource.getCurrentPlaylist(
        apiToken: apiToken,
        now: serverNow,
      );

      final normalizedPlaylist = _mediaCacheService.normalizePlaylistMediaUrls(
        playlist,
      );
      final playbackPlaylist = await _mediaCacheService
          .attachCachedPlaylistMedia(normalizedPlaylist);

      await _localDataSource.cacheCurrentPlaylist(playbackPlaylist);
      unawaited(_cachePlaylistForOffline(playbackPlaylist, apiToken));

      return playbackPlaylist;
    } catch (error, stackTrace) {
      debugPrint('Schedule sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      final cachedPlaylist = await _localDataSource.getCachedCurrentPlaylist();

      if (cachedPlaylist.isNotEmpty) {
        debugPrint(
          'Using cached schedule playlist with ${cachedPlaylist.length} item(s).',
        );
        return cachedPlaylist;
      }

      throw Exception('Không thể tải lịch phát: $error');
    }
  }

  Future<void> _cachePlaylistForOffline(
    List<PlayableMedia> playlist,
    String apiToken,
  ) async {
    try {
      final offlinePlaylist = await _mediaCacheService.cachePlaylistMedia(
        playlist,
        bearerToken: apiToken,
      );

      await _localDataSource.cacheCurrentPlaylist(offlinePlaylist);
    } catch (error, stackTrace) {
      debugPrint('Background offline media cache failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<Duration> getServerClockOffset({required String? apiToken}) async {
    try {
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('Missing device API token');
      }

      final serverNow = await _remoteDataSource.getServerTime(
        apiToken: apiToken,
      );
      final offset = serverNow.difference(DateTime.now());
      await _localDataSource.cacheServerClockOffset(offset);

      return offset;
    } catch (_) {
      return await _localDataSource.getCachedServerClockOffset() ??
          Duration.zero;
    }
  }

  Future<Duration> getScheduleRefreshInterval({
    required String? apiToken,
  }) async {
    try {
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('Missing device API token');
      }

      final config = await _remoteDataSource.getSyncConfig(apiToken: apiToken);
      await _localDataSource.cacheScheduleRefreshInterval(
        config.refreshInterval,
      );

      return config.refreshInterval;
    } catch (_) {
      return await _localDataSource.getCachedScheduleRefreshInterval() ??
          ScheduleSyncConfig.defaultRefreshInterval;
    }
  }
}
