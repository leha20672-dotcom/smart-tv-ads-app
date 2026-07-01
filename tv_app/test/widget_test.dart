import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tv_app/src/core/network/api_client.dart';
import 'package:tv_app/src/features/device/data/device_remote_data_source.dart';
import 'package:tv_app/src/features/player/data/playback_log_remote_data_source.dart';
import 'package:tv_app/src/features/player/domain/playback_log.dart';
import 'package:tv_app/src/features/schedule/data/schedule_remote_data_source.dart';
import 'package:tv_app/src/features/schedule/domain/media.dart';
import 'package:tv_app/src/features/schedule/domain/playable_media.dart';
import 'package:tv_app/src/features/schedule/domain/schedule_sync_config.dart';

void main() {
  test('device registration follows register-device approval flow', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;

      expect(request.method, 'POST');
      expect(request.url.path, '/api/register-device');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['device_code'], 'BOX-001');
      expect(body['name'], 'Lobby Screen');

      if (requestCount == 1) {
        return http.Response(
          jsonEncode({
            'status': 'pending',
            'message': 'Waiting for admin approval',
          }),
          202,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode({
          'status': 'active',
          'message': 'Approved',
          'device_token': 'device-token',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final dataSource = DeviceRemoteDataSource(
      ApiClient(client: client, baseUrl: 'http://example.test/api'),
    );

    final registration = await dataSource.registerDevice(
      deviceCode: 'BOX-001',
      name: 'Lobby Screen',
    );
    final status = await dataSource.checkPairing(
      deviceCode: 'BOX-001',
      name: 'Lobby Screen',
    );

    expect(registration.status, 'pending');
    expect(registration.deviceToken, isNull);
    expect(status.status, 'active');
    expect(status.deviceToken, 'device-token');
  });

  test('media parser accepts schedule API playlist item', () {
    final media = Media.fromJson({
      'media_id': 9,
      'title': 'Promo',
      'file_url': 'https://example.com/storage/promo.mp4',
      'type': 'video',
    });

    expect(media.id, 9);
    expect(media.name, 'Promo');
    expect(media.fileType, MediaType.video);
  });

  test('playable media keeps synced timeline metadata', () {
    final playableMedia = PlayableMedia.fromJson({
      'schedule_id': 5,
      'schedule_name': 'Morning',
      'media': {
        'media_id': 9,
        'title': 'Promo',
        'file_url': 'https://example.com/storage/promo.mp4',
        'type': 'video',
      },
      'duration': 4,
      'timeline_start_second': 1,
      'timeline_end_second': 5,
      'schedule_start_at': '2026-06-23T08:00:00.000',
      'schedule_end_at': '2026-06-23T20:00:00.000',
      'is_synced_timeline': true,
    });

    expect(playableMedia.timelineStartSecond, 1);
    expect(playableMedia.timelineEndSecond, 5);
    expect(playableMedia.isSyncedTimeline, isTrue);
    expect(playableMedia.scheduleStartDateTime?.hour, 8);
    expect(playableMedia.scheduleEndDateTime?.hour, 20);
  });

  test('schedule API parses nested get-schedule playlist', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/get-schedule');
      expect(request.headers['authorization'], 'Bearer device-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'playlist': [
            {
              'schedule_id': 7,
              'schedule_name': 'Morning',
              'date_start': '2026-06-22 - 08:00:00',
              'date_end': '2026-06-22 - 20:00:00',
              'days_active': '2, 3, 8',
              'playlist': [
                {
                  'media_id': 9,
                  'file_name': 'promo.mp4',
                  'download_url': 'http://example.test/api/download-media/9',
                  'zone_name': 'main_zone',
                  'play_order': 1,
                  'duration': 15,
                },
              ],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final dataSource = ScheduleRemoteDataSource(
      ApiClient(client: client, baseUrl: 'http://example.test/api'),
    );

    final playlist = await dataSource.getCurrentPlaylist(
      apiToken: 'device-token',
      now: DateTime(2026, 6, 22, 9),
    );

    expect(playlist, hasLength(1));
    expect(playlist.single.scheduleId, 7);
    expect(playlist.single.media.id, 9);
    expect(playlist.single.media.fileType, MediaType.video);
    expect(playlist.single.timelineStartSecond, 0);
    expect(playlist.single.timelineEndSecond, 15);
    expect(playlist.single.scheduleStartDateTime?.hour, 8);
    expect(playlist.single.scheduleEndDateTime?.hour, 20);
  });

  test(
    'schedule API keeps upcoming schedule for today before start time',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'playlist': [
              {
                'schedule_id': 8,
                'schedule_name': 'Evening',
                'date_start': '2026-06-25 - 17:30:00',
                'date_end': '2026-06-25 - 18:00:00',
                'days_active': '5',
                'playlist': [
                  {
                    'media_id': 10,
                    'file_name': 'evening.mp4',
                    'download_url': 'http://example.test/api/download-media/10',
                    'zone_name': 'main_zone',
                    'play_order': 1,
                    'duration': 30,
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final dataSource = ScheduleRemoteDataSource(
        ApiClient(client: client, baseUrl: 'http://example.test/api'),
      );

      final playlist = await dataSource.getCurrentPlaylist(
        apiToken: 'device-token',
        now: DateTime(2026, 6, 25, 17),
      );

      expect(playlist, hasLength(1));
      expect(playlist.single.scheduleId, 8);
      expect(playlist.single.scheduleStartDateTime?.hour, 17);
      expect(playlist.single.scheduleStartDateTime?.minute, 30);
    },
  );

  test('server time prefers backend wall clock over timestamp', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/server-time');

      return http.Response(
        jsonEncode({
          'status': 'success',
          'timezone': 'Asia/Ho_Chi_Minh',
          'server_time': '2026-06-25 17:30:00',
          'timestamp': 0,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final dataSource = ScheduleRemoteDataSource(
      ApiClient(client: client, baseUrl: 'http://example.test/api'),
    );

    final serverTime = await dataSource.getServerTime(apiToken: 'device-token');

    expect(serverTime.year, 2026);
    expect(serverTime.month, 6);
    expect(serverTime.day, 25);
    expect(serverTime.hour, 17);
    expect(serverTime.minute, 30);
  });

  test('playback log API uses updateMediaLog contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/updateMediaLog');
      expect(request.headers['authorization'], 'Bearer device-token');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['schedule_id'], 7);
      expect(body['logs'], hasLength(1));
      expect(body['logs'][0]['media_id'], 9);
      expect(body['logs'][0]['played_at'], '2026-06-22 09:30:04');

      return http.Response(
        jsonEncode({'success': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final dataSource = PlaybackLogRemoteDataSource(
      ApiClient(client: client, baseUrl: 'http://example.test/api'),
    );

    await dataSource.sendCompletedLog(
      apiToken: 'device-token',
      log: PlaybackLog(
        id: 'log-1',
        scheduleId: 7,
        mediaId: 9,
        startedAt: DateTime(2026, 6, 22, 9, 29),
        endedAt: DateTime(2026, 6, 22, 9, 30, 4),
        status: PlaybackLogStatus.completed,
      ),
    );
  });

  test('schedule sync interval is clamped to fast polling', () {
    final config = ScheduleSyncConfig.fromJson({
      'schedule_refresh_interval_minutes': 30,
    });

    expect(config.refreshInterval, const Duration(seconds: 30));
  });
}
