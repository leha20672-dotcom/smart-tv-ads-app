import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/media.dart';
import '../domain/playable_media.dart';

class MediaCacheService {
  MediaCacheService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout ??= const Duration(seconds: 10);
  }

  static const _cacheFolderName = 'offline_media';

  final Dio _dio;

  List<PlayableMedia> normalizePlaylistMediaUrls(List<PlayableMedia> playlist) {
    if (playlist.isEmpty) {
      return playlist;
    }

    return playlist.map((playableMedia) {
      final media = playableMedia.media;

      if (!_isDownloadableMedia(media)) {
        return playableMedia;
      }

      final preferredUrl = _preferredPlaybackUrl(media.filePath);
      if (preferredUrl == null || preferredUrl == media.filePath) {
        return playableMedia;
      }

      return playableMedia.copyWith(
        media: media.copyWith(filePath: preferredUrl),
      );
    }).toList();
  }

  Future<List<PlayableMedia>> attachCachedPlaylistMedia(
    List<PlayableMedia> playlist,
  ) async {
    if (playlist.isEmpty) {
      return playlist;
    }

    try {
      final cacheDirectory = await _ensureCacheDirectory();
      final cachedPlaylist = <PlayableMedia>[];

      for (final playableMedia in playlist) {
        cachedPlaylist.add(
          await _attachCachedPlayableMedia(playableMedia, cacheDirectory),
        );
      }

      return cachedPlaylist;
    } catch (error) {
      debugPrint('Existing offline media lookup unavailable: $error');
      return playlist;
    }
  }

  Future<List<PlayableMedia>> cachePlaylistMedia(
    List<PlayableMedia> playlist, {
    String? bearerToken,
  }) async {
    if (playlist.isEmpty) {
      return playlist;
    }

    try {
      final cacheDirectory = await _ensureCacheDirectory();
      final cachedPlaylist = <PlayableMedia>[];

      for (final playableMedia in playlist) {
        try {
          cachedPlaylist.add(
            await _cachePlayableMedia(
              playableMedia,
              cacheDirectory,
              bearerToken: bearerToken,
            ),
          );
        } catch (error) {
          debugPrint(
            'Skipping offline cache for media '
            '${playableMedia.media.id}: $error',
          );
          cachedPlaylist.add(playableMedia);
        }
      }

      return cachedPlaylist;
    } catch (error) {
      debugPrint('Offline media cache unavailable: $error');
      return playlist;
    }
  }

  Future<PlayableMedia> _cachePlayableMedia(
    PlayableMedia playableMedia,
    Directory cacheDirectory, {
    String? bearerToken,
  }) async {
    final media = playableMedia.media;

    if (!_isDownloadableMedia(media)) {
      return playableMedia;
    }

    final existingLocalFile = await _existingLocalFile(media);
    if (existingLocalFile != null) {
      return playableMedia.copyWith(
        media: media.copyWith(localFilePath: existingLocalFile.path),
      );
    }

    final targetFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}${_cacheFileName(media)}',
    );

    if (await _isUsableCachedFile(targetFile, media)) {
      return playableMedia.copyWith(
        media: media.copyWith(localFilePath: targetFile.path),
      );
    }

    final downloadUrls = _downloadUrlsFor(media.filePath);

    for (final downloadUrl in downloadUrls) {
      try {
        await _downloadMedia(
          downloadUrl: downloadUrl,
          targetFile: targetFile,
          bearerToken: bearerToken,
        );

        if (await _isUsableCachedFile(targetFile, media)) {
          return playableMedia.copyWith(
            media: media.copyWith(localFilePath: targetFile.path),
          );
        }
      } catch (error) {
        debugPrint('Media cache download failed for $downloadUrl: $error');
      }
    }

    if (await targetFile.exists() && await targetFile.length() > 0) {
      return playableMedia.copyWith(
        media: media.copyWith(localFilePath: targetFile.path),
      );
    }

    return playableMedia;
  }

  Future<PlayableMedia> _attachCachedPlayableMedia(
    PlayableMedia playableMedia,
    Directory cacheDirectory,
  ) async {
    final media = playableMedia.media;

    if (!_isDownloadableMedia(media)) {
      return playableMedia;
    }

    final existingLocalFile = await _existingLocalFile(media);
    if (existingLocalFile != null) {
      return playableMedia.copyWith(
        media: media.copyWith(localFilePath: existingLocalFile.path),
      );
    }

    final targetFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}${_cacheFileName(media)}',
    );

    if (await _isUsableCachedFile(targetFile, media)) {
      return playableMedia.copyWith(
        media: media.copyWith(localFilePath: targetFile.path),
      );
    }

    return playableMedia;
  }

  Future<Directory> _ensureCacheDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}$_cacheFolderName',
    );

    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    return cacheDirectory;
  }

  bool _isDownloadableMedia(Media media) {
    if (media.filePath.trim().isEmpty) {
      return false;
    }

    return media.fileType == MediaType.image ||
        media.fileType == MediaType.video ||
        media.fileType == MediaType.music;
  }

  Future<File?> _existingLocalFile(Media media) async {
    final localFilePath = media.localFilePath;

    if (localFilePath == null || localFilePath.isEmpty) {
      return null;
    }

    final localFile = _fileFromPath(localFilePath);

    if (await _isUsableCachedFile(localFile, media)) {
      return localFile;
    }

    return null;
  }

  Future<bool> _isUsableCachedFile(File file, Media media) async {
    if (!await file.exists()) {
      return false;
    }

    final fileLength = await file.length();
    if (fileLength <= 0) {
      return false;
    }

    final expectedSize = media.fileSize;
    if (expectedSize != null && expectedSize > 0) {
      return fileLength == expectedSize;
    }

    return true;
  }

  Future<void> _downloadMedia({
    required String downloadUrl,
    required File targetFile,
    String? bearerToken,
  }) async {
    await targetFile.parent.create(recursive: true);

    final tempFile = File('${targetFile.path}.download');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    await _dio.download(
      downloadUrl,
      tempFile.path,
      options: Options(
        headers: {
          if (bearerToken != null && bearerToken.isNotEmpty)
            'Authorization': 'Bearer $bearerToken',
        },
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.bytes,
      ),
    );

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await tempFile.rename(targetFile.path);
  }

  List<String> _downloadUrlsFor(String rawPath) {
    final trimmedPath = rawPath.trim();
    if (trimmedPath.isEmpty) {
      return [];
    }

    final parsedUri = Uri.tryParse(trimmedPath);
    if (parsedUri != null && parsedUri.hasScheme) {
      if (parsedUri.scheme == 'http' || parsedUri.scheme == 'https') {
        return _downloadUrlsForAbsoluteUri(parsedUri);
      }

      return [];
    }

    final urls = <String>{};

    for (final baseUrl in _apiBaseUrlCandidates()) {
      final parsedBaseUrl = Uri.tryParse(baseUrl);
      if (parsedBaseUrl == null || !parsedBaseUrl.hasScheme) {
        continue;
      }

      final serverRoot = parsedBaseUrl.replace(
        path: '/',
        query: '',
        fragment: '',
      );
      urls.add(serverRoot.resolve(trimmedPath).toString());

      final apiBase = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      urls.add(apiBase.resolve(trimmedPath).toString());
    }

    return urls.toList();
  }

  String? _preferredPlaybackUrl(String rawPath) {
    final urls = _downloadUrlsFor(rawPath);

    if (urls.isEmpty) {
      return null;
    }

    return urls.first;
  }

  List<String> _downloadUrlsForAbsoluteUri(Uri uri) {
    final urls = <String>{};
    final rawUrl = uri.toString();
    final isLoopbackHost =
        uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '0.0.0.0' ||
        uri.host == '::1';

    if (!isLoopbackHost) {
      urls.add(rawUrl);
    }

    for (final baseUrl in _apiBaseUrlCandidates()) {
      final parsedBaseUrl = Uri.tryParse(baseUrl);
      if (parsedBaseUrl == null || !parsedBaseUrl.hasScheme) {
        continue;
      }

      urls.add(
        parsedBaseUrl
            .replace(path: uri.path, query: uri.query, fragment: '')
            .toString(),
      );
    }

    urls.add(rawUrl);

    return urls.toList();
  }

  List<String> _apiBaseUrlCandidates() {
    return {
      if (ApiClient.lastSuccessfulBaseUrl?.isNotEmpty == true)
        ApiClient.lastSuccessfulBaseUrl!,
      ...AppConfig.fallbackBaseUrls,
    }.toList();
  }

  String _cacheFileName(Media media) {
    final sourceName = _sourceFileName(media.filePath);
    final extension =
        _extensionFromName(sourceName) ??
        _extensionFromName(media.filePath) ??
        _defaultExtension(media.fileType);
    final baseName = _safeFilePart(_stripExtension(sourceName));
    final mediaKey = media.id > 0 ? '${media.id}' : _stableSourceKey(media);

    return '${media.fileType.name}_${mediaKey}_$baseName$extension';
  }

  String _sourceFileName(String value) {
    final uri = Uri.tryParse(value);
    final pathSegments = uri?.pathSegments ?? const <String>[];

    if (pathSegments.isNotEmpty && pathSegments.last.isNotEmpty) {
      return pathSegments.last;
    }

    return 'media';
  }

  String? _extensionFromName(String value) {
    final dotIndex = value.lastIndexOf('.');

    if (dotIndex < 0 || dotIndex == value.length - 1) {
      return null;
    }

    final extension = value.substring(dotIndex).toLowerCase();

    if (extension.length > 12 ||
        !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
      return null;
    }

    return extension;
  }

  String _defaultExtension(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.image:
        return '.jpg';
      case MediaType.video:
        return '.mp4';
      case MediaType.music:
        return '.mp3';
      case MediaType.url:
        return '.html';
    }
  }

  String _stripExtension(String value) {
    final dotIndex = value.lastIndexOf('.');

    if (dotIndex <= 0) {
      return value;
    }

    return value.substring(0, dotIndex);
  }

  String _safeFilePart(String value) {
    final safeValue = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (safeValue.isEmpty) {
      return 'media';
    }

    return safeValue.length > 80 ? safeValue.substring(0, 80) : safeValue;
  }

  String _stableSourceKey(Media media) {
    var hash = 2166136261;

    for (final codeUnit in media.filePath.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  File _fileFromPath(String path) {
    final uri = Uri.tryParse(path);

    if (uri != null && uri.scheme == 'file') {
      return File.fromUri(uri);
    }

    return File(path);
  }
}
