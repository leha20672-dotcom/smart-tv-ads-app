import 'package:flutter_test/flutter_test.dart';
import 'package:tv_app/src/features/schedule/domain/media.dart';

void main() {
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
}
