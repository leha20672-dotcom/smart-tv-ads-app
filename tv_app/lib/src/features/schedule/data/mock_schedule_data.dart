final mockDeviceJson = {
  'id': 1,
  'address_id': 1,
  'name': 'Tivi Cổng 1',
  'device_code': 'TV-123456',
  'status': 'online',
};

final mockAddressScheduleJson = [
  {
    'id': 1,
    'address_id': 1,
    'schedule_id': 1,
  },
];

final mockSchedulesJson = [
  {
    'id': 1,
    'name': 'Promo Mùa Hè',
    'start_date': '2020-01-01',
    'end_date': '2099-12-31',
    'start_time': '00:00:00',
    'end_time': '23:59:59',
    'days_of_week': [1, 2, 3, 4, 5, 6, 7],
  },
];

final mockScheduleMediaJson = [
  {
    'id': 1,
    'schedule_id': 1,
    'media_id': 1,
    'zone_name': 'main_zone',
    'play_order': 1,
    'duration': 5,
  },
  {
    'id': 2,
    'schedule_id': 1,
    'media_id': 2,
    'zone_name': 'main_zone',
    'play_order': 2,
    'duration': 10,
  },
];

final mockMediaJson = [
  {
    'id': 1,
    'name': 'Ảnh quảng cáo 1',
    'file_path': 'assets/images/photo_1.jpg',
    'file_type': 'image',
    'file_size': 102400,
  },
  {
    'id': 2,
    'name': 'Video quảng cáo 1',
    'file_path': 'assets/videos/video_1.mp4',
    'file_type': 'video',
    'file_size': 2048000,
  },
];
