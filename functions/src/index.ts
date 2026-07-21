import { initializeApp } from 'firebase-admin/app';

// 폴러 모듈이 getFirebaseApp()을 부르기 전에 기본 앱을 초기화한다(자격증명 자동 = ADC).
// Functions 런타임은 GOOGLE_APPLICATION_CREDENTIALS/메타데이터 서버로 인증되므로 인자 불필요.
initializeApp();

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

import { pollAndPushAlerts } from '../../backend/src/alerts/poller';
import { pollAndAccumulatePrecip } from '../../backend/src/precip/poller';

// KMA 서비스 키는 Secret Manager로 주입한다(코드/환경변수에 평문 저장 안 함).
// backend/src/config.ts가 process.env.KMA_SERVICE_KEY를 lazy로 읽으므로, 폴 처리
// 중(런타임)에 이 시크릿이 env로 보이도록 secrets에 바인딩만 해주면 된다.
const KMA_SERVICE_KEY = defineSecret('KMA_SERVICE_KEY');

/**
 * 5분마다 특보 폴링(→ FCM 푸시)과 강수 누적 폴링(→ Firestore)을 실행한다.
 * 예전엔 외부 크론(cron-job.org)이 Render의 /internal/poll-alerts를 두드려 이 둘을
 * 구동했지만, 이제 스케줄러가 직접 호출한다 — Render를 24/7 warm으로 유지할 필요가
 * 사라져 무료 인스턴스 시간을 아낀다.
 *
 * 둘은 서로 독립이므로 allSettled로 동시에 돌리고, 한쪽이 실패해도 다른 쪽은 반영된다.
 */
export const pollWeather = onSchedule(
  {
    schedule: '*/5 * * * *',
    timeZone: 'Asia/Seoul',
    region: 'asia-northeast3',
    secrets: [KMA_SERVICE_KEY],
    timeoutSeconds: 300,
    memory: '256MiB',
    // 비용 안전장치: 스케줄 함수는 5분에 한 번만 돌므로 인스턴스가 많이 필요 없다.
    // 상한을 낮게 묶어 버그·폭주가 있어도 비용이 커질 수 없게 한다(예산 알림은
    // 과금을 막지 못하므로, 실제 하드 가드는 여기서 건다).
    maxInstances: 2,
  },
  async () => {
    const [alerts, precip] = await Promise.allSettled([
      pollAndPushAlerts(),
      pollAndAccumulatePrecip(),
    ]);

    if (alerts.status === 'fulfilled') {
      const pushed = alerts.value.filter((r) => r.pushed).length;
      logger.info(`[pollWeather] 특보 폴 완료 — ${pushed}건 푸시`, { results: alerts.value });
    } else {
      logger.error('[pollWeather] 특보 폴 실패', { error: String(alerts.reason) });
    }

    if (precip.status === 'fulfilled') {
      logger.info(`[pollWeather] 강수 폴 완료`, precip.value);
    } else {
      logger.error('[pollWeather] 강수 폴 실패', { error: String(precip.reason) });
    }
  },
);
