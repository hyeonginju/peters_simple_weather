import { Router } from 'express';

import { config } from '../config';
import { pollAndPushAlerts } from '../alerts/poller';

export const internalRouter = Router();

/**
 * GitHub Actions cron이 10분마다 호출하는 트리거. 9개 관서를 확인하고 최근 발표된
 * 발효 특보가 있으면 해당 토픽으로 푸시를 보낸다. 동시에 이 요청 자체가 Render
 * 무료 티어 슬립을 막아준다(폴링 트리거 겸 keep-warm).
 */
internalRouter.post('/poll-alerts', async (req, res) => {
  if (req.header('x-poll-secret') !== config.pollSecret) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  try {
    const results = await pollAndPushAlerts();
    res.json({ results });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[poll-alerts] 실패: ${message}`);
    res.status(500).json({ error: message });
  }
});
