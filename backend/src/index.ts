import express from 'express';

import { config } from './config';
import { weatherRouter } from './routes/weather';

const app = express();

// 헬스체크용. (폴링은 Firebase Scheduled Function으로 이관돼 더 이상 이 서버를
// 외부 크론으로 깨울 필요가 없다 — functions/src/index.ts 참고.)
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api/weather', weatherRouter);

app.listen(config.port, () => {
  console.log(`peters-weather-backend listening on :${config.port}`);
});
