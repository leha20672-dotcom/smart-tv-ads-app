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
    return Media(
      id: json['id'] as int,
      name: json['name'] as String,
      filePath: json['file_path'] as String,
      fileType: _mediaTypeFromString(json['file_type'] as String),
      fileSize: json['file_size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_Path': filePath,
      'file_type': fileType.name,
      'file_size': fileSize,
    };
  }

  static MediaType _mediaTypeFromString(String value) {
    switch (value) {
      case 'image':
        return MediaType.image;
      case 'video': 
        return MediaType.video;
      case 'url': 
        return MediaType.url;
      case 'music': 
        return MediaType.music;
      default:
        return MediaType.image;
    }
  }
}