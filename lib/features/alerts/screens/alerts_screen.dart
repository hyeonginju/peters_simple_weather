import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/alert/kma_stn_mapper.dart';
import '../../../data/alert/models/weather_alert.dart';
import '../../home/providers/weather_providers.dart';
import '../../home/widgets/error_full_screen.dart';
import '../../push/push_service.dart';
import '../../region_picker/providers/region_providers.dart';
import '../providers/alert_providers.dart';

/// 기상특보 발효 현황. 기본은 현재 지역의 시/도 권역, 토글로 전국 전환.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _nationwide = false;

  @override
  void initState() {
    super.initState();
    unawaited(_maybeRequestPushPermission());
  }

  /// 특보 화면 첫 진입 시 1회만 알림 권한을 요청하고 대표 지역 토픽을 구독한다.
  Future<void> _maybeRequestPushPermission() async {
    if (await PushService.hasRequestedPermission()) return;
    final regions = await ref.read(savedRegionsProvider.future);
    await PushService.requestPermissionAndSubscribe(regions.isEmpty ? null : regions.first);
  }

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(activeRegionProvider).asData?.value;
    // 지역이 없으면 전국만 볼 수 있다.
    final canShowRegion = region != null;
    final showNationwide = _nationwide || !canShowRegion;
    final stnId = showNationwide ? KmaStnMapper.nationwide : KmaStnMapper.stnIdForProvince(region.province);
    final statusAsync = ref.watch(alertStatusProvider(stnId));

    return Scaffold(
      appBar: AppBar(title: const Text('기상특보')),
      body: Column(
        children: [
          if (canShowRegion)
            _ScopeToggle(
              nationwide: showNationwide,
              regionLabel: KmaStnMapper.labelForStnId(KmaStnMapper.stnIdForProvince(region.province)),
              onChanged: (value) => setState(() => _nationwide = value),
            ),
          Expanded(
            child: statusAsync.when(
              data: (status) => _AlertBody(status: status, stnId: stnId),
              loading: () => const _DelayedLoadingHint(),
              error: (_, _) => ErrorFullScreen(
                onRetry: () => ref.read(alertStatusProvider(stnId).notifier).forceRefresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 내 지역 / 전국 세그먼트 토글.
class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.nationwide, required this.regionLabel, required this.onChanged});

  final bool nationwide;
  final String regionLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: palette.searchBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _ToggleItem(label: regionLabel, selected: !nationwide, onTap: () => onChanged(false), palette: palette),
            _ToggleItem(label: '전국', selected: nationwide, onTap: () => onChanged(true), palette: palette),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({required this.label, required this.selected, required this.onTap, required this.palette});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? palette.textPrimary : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// 특보 로딩 스피너. 서버(Render 무료 플랜)가 잠들어 있으면 깨우는 데 20초+
/// 걸리는데, 스피너만 돌면 멈춘 것처럼 보인다 — 몇 초 지나면 이유를 알려준다.
class _DelayedLoadingHint extends StatefulWidget {
  const _DelayedLoadingHint();

  @override
  State<_DelayedLoadingHint> createState() => _DelayedLoadingHintState();
}

class _DelayedLoadingHintState extends State<_DelayedLoadingHint> {
  static const _hintAfter = Duration(seconds: 5);

  Timer? _timer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hintAfter, () => setState(() => _showHint = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (_showHint) ...[
            const SizedBox(height: 18),
            Text(
              '서버를 깨우는 중이에요…\n최대 30초 정도 걸릴 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: context.palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBody extends ConsumerWidget {
  const _AlertBody({required this.status, required this.stnId});

  final WeatherAlertStatus status;
  final String stnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final announced = status.announcedAt;
    final refreshing = ref.watch(alertRefreshingProvider(stnId));
    final muted = TextStyle(fontSize: 12, color: palette.textMuted);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                status.regionLabel,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.textPrimary),
              ),
              const Spacer(),
              // 직전 통보문(stale)을 먼저 그리고 뒤에서 갱신 중일 때의 표시 —
              // 홈 _UpdatedLabel과 같은 SWR 인디케이터.
              if (refreshing) ...[
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
                const SizedBox(width: 5),
                Text('업데이트 중', style: muted),
              ] else if (announced != null)
                Text(formatAnnouncedLabel(announced), style: muted),
            ],
          ),
          const SizedBox(height: 16),
          if (status.hasActiveAlert)
            _AlertCard(
              title: '현재 발효 중인 특보',
              body: status.currentAlerts,
              accent: palette.danger,
              accentBg: palette.dangerBg,
              palette: palette,
            )
          else
            _NoAlertCard(palette: palette),
          if (status.preliminaryAlerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            _AlertCard(
              title: '예비특보',
              body: status.preliminaryAlerts,
              accent: palette.point,
              accentBg: palette.pointBg,
              palette: palette,
            ),
          ],
          if (status.latestTitle.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('최근 변경', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.textMuted)),
            const SizedBox(height: 6),
            Text(status.latestTitle, style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.body,
    required this.accent,
    required this.accentBg,
    required this.palette,
  });

  final String title;
  final String body;
  final Color accent;
  final Color accentBg;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(8)),
            child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
          ),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(fontSize: 14, height: 1.55, color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _NoAlertCard extends StatelessWidget {
  const _NoAlertCard({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 40, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            '현재 발효 중인 특보가 없습니다',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
