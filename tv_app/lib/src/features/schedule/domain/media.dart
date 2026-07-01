enum MediaType { image, video, url, music }

class Media {
  const Media({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileType,
    this.fileSize,
    this.localFilePath,
  });

  final int id;
  final String name;
  final String filePath;
  final MediaType fileType;
  final int? fileSize;
  final String? localFilePath;

  String get playbackPath {
    final path = localFilePath;
    if (path != null && path.isNotEmpty) {
      return path;
    }

    return filePath;
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    final filePath =
        (json['file_url'] ??
                json['download_url'] ??
                json['file_path'] ??
                json['url'] ??
                '')
            .toString();
    final name = (json['name'] ?? json['title'] ?? json['file_name'] ?? '')
        .toString();
    final typeValue =
        (json['file_type'] ??
                json['type'] ??
                json['media_type'] ??
                json['mime_type'] ??
                '')
            .toString();
    final localFilePath = json['local_file_path'] ?? json['local_path'];

    return Media(
      id: _asInt(json['id'] ?? json['media_id']),
      name: name,
      filePath: filePath,
      fileType: _mediaTypeFromString(
        typeValue.isEmpty ? '$filePath $name' : typeValue,
      ),
      fileSize: _asNullableInt(json['file_size']),
      localFilePath: localFilePath is String && localFilePath.isNotEmpty
          ? localFilePath
          : null,
    );
  }

  Media copyWith({
    int? id,
    String? name,
    String? filePath,
    MediaType? fileType,
    int? fileSize,
    String? localFilePath,
  }) {
    return Media(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'file_type': fileType.name,
      'file_size': fileSize,
      if (localFilePath != null && localFilePath!.isNotEmpty)
        'local_file_path': localFilePath,
    };
  }

  static MediaType _mediaTypeFromString(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('video')) return MediaType.video;
    if (normalized.contains('image')) return MediaType.image;
    if (normalized.contains('audio')) return MediaType.music;

    switch (normalized) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'url':
        return MediaType.url;
      case 'music':
        return MediaType.music;
      default:
        return _mediaTypeFromPath(value);
    }
  }

  static MediaType _mediaTypeFromPath(String value) {
    final normalized = value.toLowerCase();

    if (normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.m3u8')) {
      return MediaType.video;
    }

    if (normalized.endsWith('.mp3') ||
        normalized.endsWith('.wav') ||
        normalized.endsWith('.aac') ||
        normalized.endsWith('.m4a') ||
        normalized.endsWith('.ogg') ||
        normalized.endsWith('.flac')) {
      return MediaType.music;
    }

    if (normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp') ||
        normalized.endsWith('.gif')) {
      return MediaType.image;
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return MediaType.url;
    }

    return MediaType.image;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }
}
