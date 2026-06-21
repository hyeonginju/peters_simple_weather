import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../hourly_timeline_builder.dart';
import '../hourly_timeline_entry.dart';
import 'hourly_timeline.dart';

/// 시간별 예보 카드 — 가로 스크롤 타임라인 + 상단 중앙에 현재 중앙 셀의
/// 날짜 라벨(오늘 20일 → 내일 21일 → 모레 22일). 0시 셀이 화면 중앙에
/// 들어오는 순간 다음 날로 바뀐다.
class HourlyForecastCard extends StatefulWidget {
  const HourlyForecastCard({super.key, required this.entries, required this.today});

  final List<HourlyTimelineEntry> entries;
  final DateTime today;

  @override
  State<HourlyForecastCard> createState() => _HourlyForecastCardState();
}

class _HourlyForecastCardState extends State<HourlyForecastCard> {
  final _controller = ScrollController();
  final _centeredIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final center = pos.pixels + pos.viewportDimension / 2 - kHourTimelinePadding;
    final idx = (center / kHourCellWidth).floor().clamp(0, widget.entries.length - 1);
    if (idx != _centeredIndex.value) _centeredIndex.value = idx;
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _centeredIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('시간별 예보', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _centeredIndex,
                  builder: (context, idx, _) {
                    final time = widget.entries[idx.clamp(0, widget.entries.length - 1)].time;
                    return Text(
                      hourlyDateLabel(time, today: widget.today),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.point),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: HourlyTimeline(entries: widget.entries, controller: _controller),
          ),
        ],
      ),
    );
  }
}
