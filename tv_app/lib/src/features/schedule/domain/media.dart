enum MediaType {
  image,
  video,
  url,
  music,
}

class Media {
  const Media({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileType,
    this.fileSize,
  });

  final int id;
  final String name;
  final String filePath;
  final MediaType fileType;
  final int? fileSize;

  factory Media.fromJson(Map<String, dynamic> json) {
    final filePath =
        (json['file_url'] ?? json['file_path'] ?? json['url'] ?? '') as String;
    final typeValue = (json['file_type'] ?? json['type'] ?? '') as String;

    return Media(
      id: _asInt(json['id'] ?? json['media_id']),
      name: (json['name'] ?? json['title'] ?? '') as String,
      filePath: filePath,
      fileType: _mediaTypeFromString(typeValue.isEmpty ? filePath : typeValue),
      fileSize: _asNullableInt(json['file_size']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'file_type': fileType.name,
      'file_size': fileSize,
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

    if (normalized.endsWith('.mp3') || normalized.endsWith('.wav')) {
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
