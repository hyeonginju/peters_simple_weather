import express from 'express';

import { config } from './config';
import { internalRouter } from './routes/internal';

const app = express();

// Render 등 무료 티어의 콜드스타트 깨우기 + 헬스체크용.
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/internal', internalRouter);

app.listen(config.port, () => {
  console.log(`peters-weather-backend listening on :${config.port}`);
});
