const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

/// 주간 예보 날짜 라벨. 오늘이면 "오늘", 아니면 "토 6월20일" 형식.
String formatWeeklyDayLabel(DateTime date, {required DateTime today}) {
  if (date.year == today.year && date.month == today.month && date.day == today.day) {
    return '오늘';
  }
  final weekday = _weekdayLabels[date.weekday - 1];
  return '$weekday ${date.month}월${date.day}일';
}

/// 시간별 예보의 시간 라벨, "16시" 형식.
String formatHourLabel(DateTime time) => '${time.hour}시';

/// 마지막 업데이트 시각 라벨, "08:05 업데이트" 형식.
String formatUpdatedLabel(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m 업데이트';
}

/// 특보 발표 시각 라벨, "06.20 07:00 발표" 형식.
String formatAnnouncedLabel(DateTime time) {
  final mo = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  final h = time.hour.toString().padLeft(2, '0');
  final mi = time.minute.toString().padLeft(2, '0');
  return '$mo.$d $h:$mi 발표';
}
