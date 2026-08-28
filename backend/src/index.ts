import express from 'express';

import { config } from './config';
import { weatherRouter } from './routes/weather';
import { rateLimit } from './middleware/rateLimit';

const app = express();

// Render는 리버스 프록시 뒤에서 앱을 띄운다. 이 설정이 없으면 모든 요청이
// 프록시 IP 하나로 보여서 레이트 리밋이 전체 사용자를 싸잡아 막는다.
app.set('trust proxy', 1);

// 헬스체크용. (폴링은 Firebase Scheduled Function으로 이관돼 더 이상 이 서버를
// 외부 크론으로 깨울 필요가 없다 — functions/src/index.ts 참고.)
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api/weather', rateLimit, weatherRouter);

app.listen(config.port, () => {
  console.log(`peters-weather-backend listening on :${config.port}`);
});
