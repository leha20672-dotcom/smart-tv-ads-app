import '../domain/address_schedule.dart';
import '../domain/media.dart';
import '../domain/playable_media.dart';
import '../domain/schedule.dart';
import '../domain/schedule_media.dart';

class ScheduleService {
    List<PlayableMedia> buildCurrentPlaylist({
        required int addressId,
        required List<AddressSchedule> addressSchedule,
        required List<Schedule> schedules,
        required List<ScheduleMedia> scheduleMedia,
        required List<Media> mediaList,
        DateTime? now,
    }) {
        final currentTime = now ?? DateTime.now();

        final scheduleIdsForAddress = addressSchedule
            .where((item) => item.addressId == addressId)
            .map((item) => item.scheduleId)
            .toSet();

        final activeSchedules = schedules.where((schedule) {
            return scheduleIdsForAddress.contains(schedule.id) && 
                _isScheduleActive(schedule, currentTime);
        }).toList();

        if (activeSchedules.isEmpty) {
            return [];
        }

        final result = <PlayableMedia>[];

        for (final schedule in activeSchedules) {
            final mediaLinks = scheduleMedia
                .where((item) => item.scheduleId == schedule.id)
                .toList()
                ..sort((a,b) => a.playOrder.compareTo(b.playOrder));
            
            for (final link in mediaLinks) {
                final media = mediaList
                    .where((item) => item.id == link.mediaId)
                    .firstOrNull;
                
                if (media == null) continue;

                result.add(
                    PlayableMedia(
                        scheduleId: schedule.id,
                        scheduleName: schedule.name,
                        media: media,
                        zoneName: link.zoneName,
                        playOrder: link.playOrder,
                        duration: link.duration,
                    ),
                );
            }
        }
        return result;
    }

    bool _isScheduleActive(Schedule schedule, DateTime now) {
        final today = DateTime(now.year, now.month, now.day);

        final startDate = DateTime(
            schedule.startDate.year,
            schedule.startDate.month,
            schedule.startDate.day,
        );

        final endDate = DateTime(
            schedule.endDate.year,
            schedule.endDate.month,
            schedule.endDate.day,
        );

        final isInDateRange = !today.isBefore(startDate) && !today.isAfter(endDate);

        final isInDayOfWeek = schedule.daysOfWeek.contains(now.weekday);

        final startMinutes = _timeToMinutes(schedule.startTime);
        final endMinutes = _timeToMinutes(schedule.endTime);
        final currentMinutes = now.hour * 60 + now.minute;

        final isInTimeRange = currentMinutes >= startMinutes && currentMinutes <= endMinutes;

        return isInDateRange && isInDayOfWeek && isInTimeRange;
    }

    int _timeToMinutes(String time) {
        final parts = time.split(':');

        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        return hour * 60 + minute;
    }
}
