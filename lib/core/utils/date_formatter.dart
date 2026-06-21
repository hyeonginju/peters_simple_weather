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
